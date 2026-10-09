# IDDOC development toolchain image.
# This image provides a general-purpose workspace for VS Code/Cursor Dev
# Containers and interactive CLI tools. It deliberately does not bundle or
# configure a coding-agent runtime (such as OpenCode).

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Base OS and command-line utilities. Ubuntu 24.04 provides Python 3.12.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    fzf \
    fd-find \
    git \
    gnupg \
    jq \
    less \
    openssh-client \
    ripgrep \
    shellcheck \
    software-properties-common \
    tmux \
    unzip \
    wget \
    python3 \
    python3-pip \
    python3-venv \
    corkscrew \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2 for the target architecture.
RUN arch="$(dpkg --print-architecture)" \
    && case "$arch" in \
      amd64) aws_arch="x86_64" ;; \
      arm64) aws_arch="aarch64" ;; \
      *) echo "Unsupported architecture for AWS CLI: $arch" >&2; exit 1 ;; \
    esac \
    && curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${aws_arch}.zip" -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/aws /tmp/awscliv2.zip

# Use the standard VS Code Dev Containers user and UID/GID.
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
RUN if getent group "$USER_GID" >/dev/null; then \
      existing_group="$(getent group "$USER_GID" | cut -d: -f1)"; \
      if [ "$existing_group" != "vscode" ]; then groupmod --new-name vscode "$existing_group"; fi; \
    else groupadd --gid "$USER_GID" vscode; fi \
    && if getent passwd "$USER_UID" >/dev/null; then \
      existing_user="$(getent passwd "$USER_UID" | cut -d: -f1)"; \
      if [ "$existing_user" != "vscode" ]; then usermod --login vscode --home /home/vscode --move-home "$existing_user"; fi; \
    else useradd --uid "$USER_UID" --gid "$USER_GID" --create-home --shell /bin/bash vscode; fi \
    && usermod --gid "$USER_GID" --groups "" vscode \
    && mkdir -p /home/vscode \
    && chown -R "$USER_UID:$USER_GID" /home/vscode

# Go toolchain.
ARG GO_VERSION=1.22.5
RUN curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz" \
    | tar -C /usr/local -xzf -
ENV GOPATH="/home/vscode/go"
ENV PATH="/usr/local/go/bin:/home/vscode/go/bin:${PATH}"

# Node.js LTS via nvm, installed for the non-root workspace user.
ARG NODE_VERSION=20
ENV NVM_DIR="/home/vscode/.nvm"
USER vscode
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash \
    && source "$NVM_DIR/nvm.sh" \
    && nvm install "$NODE_VERSION" \
    && nvm alias default "$NODE_VERSION" \
    && nvm use default
USER root
RUN source "$NVM_DIR/nvm.sh" \
    && ln -s "$NVM_DIR/versions/node/$(nvm current)/bin/node" /usr/local/bin/node \
    && ln -s "$NVM_DIR/versions/node/$(nvm current)/bin/npm" /usr/local/bin/npm \
    && ln -s "$NVM_DIR/versions/node/$(nvm current)/bin/npx" /usr/local/bin/npx

# Terraform and common IaC validation/security tools.
ARG TERRAFORM_VERSION=1.7.3
RUN git clone --depth=1 https://github.com/tfutils/tfenv.git /home/vscode/.tfenv \
    && chown -R vscode:vscode /home/vscode/.tfenv \
    && ln -s /home/vscode/.tfenv/bin/* /usr/local/bin/
USER vscode
RUN tfenv install "$TERRAFORM_VERSION" && tfenv use "$TERRAFORM_VERSION"
USER root

ARG TERRAFORM_DOCS_VERSION=0.18.0
RUN curl -fsSL "https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-$(dpkg --print-architecture).tar.gz" \
    | tar -C /usr/local/bin -xzf - terraform-docs \
    && chmod +x /usr/local/bin/terraform-docs

ARG TFLINT_VERSION=0.53.0
RUN curl -fsSL "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_$(dpkg --print-architecture).zip" -o /tmp/tflint.zip \
    && unzip /tmp/tflint.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/tflint \
    && rm /tmp/tflint.zip

ARG YQ_VERSION=4.44.3
RUN curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_$(dpkg --print-architecture)" -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

ARG DRIFTCTL_VERSION=0.40.0
RUN curl -fsSL "https://github.com/snyk/driftctl/releases/download/v${DRIFTCTL_VERSION}/driftctl_linux_$(dpkg --print-architecture)" -o /usr/local/bin/driftctl \
    && chmod +x /usr/local/bin/driftctl

# Trivy is installed from its upstream installer.
ARG TRIVY_VERSION=0.75.0
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
    | sh -s -- -b /usr/local/bin "v${TRIVY_VERSION}"

# Python developer utilities; system Python is marked externally managed on
# Ubuntu 24.04, hence --break-system-packages for these container-scoped tools.
RUN pip3 install --break-system-packages --no-cache-dir pre-commit commitizen boto3==1.40.15

# Configure pre-commit's native Git template integration for the workspace user.
# Git copies these standard hook wrappers into every later git clone/init run as
# vscode. Repositories without a pre-commit config skip the hooks automatically.
ENV PRE_COMMIT_TEMPLATE_DIR=/home/vscode/.cache/pre-commit/admiral-git-template
USER vscode
RUN mkdir -p "$PRE_COMMIT_TEMPLATE_DIR" \
    && git config --global init.templateDir "$PRE_COMMIT_TEMPLATE_DIR" \
    && pre-commit init-templatedir --hook-type pre-commit "$PRE_COMMIT_TEMPLATE_DIR" \
    && pre-commit init-templatedir --hook-type commit-msg "$PRE_COMMIT_TEMPLATE_DIR" \
    && pre-commit init-templatedir --hook-type pre-push "$PRE_COMMIT_TEMPLATE_DIR"
USER root

# uv/uvx and GitHub CLI support Python workflows and authenticated GitHub work.
USER vscode
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
USER root
ENV PATH="/home/vscode/.local/bin:${PATH}"

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# User shell and workspace defaults. Git identity and credentials are left to
# the developer/Dev Container configuration; no agent login is bootstrapped.
RUN printf '%s\n' \
      'export NVM_DIR="$HOME/.nvm"' \
      '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' \
      '[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"' \
      >> /home/vscode/.bashrc \
    && mkdir -p /home/vscode/workspace /home/vscode/go \
    && chown -R vscode:vscode /home/vscode

ENV TF_SUPPRESS_PROVIDER_OVERRIDE_WARNINGS=1 \
    DCTL_FILTER="" \
    DCTL_DEEP=false \
    DCTL_QUIET=true \
    DCTL_DRIFTIGNORE=".driftignore" \
    DCTL_ONLY_UNMANAGED=false \
    DCTL_NO_VERSION_CHECK=true \
    DCTL_DISABLE_TELEMETRY=true \
    AWS_REGION=us-east-1 \
    AWS_DEFAULT_REGION=us-east-1 \
    AWS_DEFAULT_OUTPUT=json

USER vscode
WORKDIR /home/vscode/workspace
CMD ["sleep", "infinity"]
