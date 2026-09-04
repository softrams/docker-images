# Dockerfile for Admiral OpenCode Development Container
# Ubuntu 24.04 base with development tools for IDDOC/Admiral workspace
#
# Includes:
#   - Node.js (via nvm) - LTS Iron (v20.x)
#   - Python 3.12 + pip
#   - Terraform (via tfenv) - 1.7.3
#   - terraform-docs, tflint, trivy, driftctl
#   - pre-commit, commitizen
#   - uv/uvx (for MCP servers)
#   - Playwright MCP (browser automation)
#   - Core CLI tools: git, jq, yq, fzf, fd, ripgrep, tmux, curl, wget
#
# SECURITY: Runs as non-root user 'opencode' (UID 1000)

FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set shell to bash
SHELL ["/bin/bash", "-c"]

# =============================================================================
# Core System Packages
# =============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Essential build tools
    build-essential \
    ca-certificates \
    gnupg \
    software-properties-common \
    # Core CLI tools
    git \
    curl \
    wget \
    unzip \
    jq \
    tmux \
    # Search tools
    fzf \
    fd-find \
    ripgrep \
    # Python 3.12 (ships with Ubuntu 24.04)
    python3 \
    python3-pip \
    python3-venv \
    # Misc
    openssh-client \
    less \
    # corkscrew for SSH proxy tunneling through Squid (network lockdown)
    corkscrew \
    && rm -rf /var/lib/apt/lists/*

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

# Create symlink for fd (Ubuntu packages it as fdfind)
RUN ln -s $(which fdfind) /usr/local/bin/fd || true

# =============================================================================
# Create non-root user 'opencode'
# =============================================================================
# Ubuntu 24.04 ships with 'ubuntu' user at UID 1000, so we use UID 1001
# to avoid conflicts. This still provides non-root security benefits.
RUN groupadd -g 1001 opencode && \
    useradd -m -u 1001 -g opencode -s /bin/bash opencode

# =============================================================================
# Go (needed for some tool builds)
# =============================================================================
# Install Go system-wide (as root), but set GOPATH for opencode user
ARG GO_VERSION=1.22.5
RUN curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz" \
    | tar -C /usr/local -xzf -
ENV PATH="/usr/local/go/bin:/home/opencode/go/bin:${PATH}"
ENV GOPATH="/home/opencode/go"

# =============================================================================
# Node.js via NVM (installed for opencode user)
# =============================================================================
ENV NVM_DIR="/home/opencode/.nvm"
ARG NODE_VERSION=20
RUN mkdir -p /home/opencode/.nvm && chown opencode:opencode /home/opencode/.nvm
USER opencode
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash \
    && source "$NVM_DIR/nvm.sh" \
    && nvm install ${NODE_VERSION} \
    && nvm alias default ${NODE_VERSION} \
    && nvm use default
USER root
# Create symlinks for node/npm to be available system-wide
RUN source "/home/opencode/.nvm/nvm.sh" \
    && ln -s "/home/opencode/.nvm/versions/node/$(nvm current)/bin/node" /usr/local/bin/node \
    && ln -s "/home/opencode/.nvm/versions/node/$(nvm current)/bin/npm" /usr/local/bin/npm \
    && ln -s "/home/opencode/.nvm/versions/node/$(nvm current)/bin/npx" /usr/local/bin/npx

# =============================================================================
# Terraform via tfenv (installed for opencode user)
# =============================================================================
ARG TERRAFORM_VERSION=1.7.3
RUN git clone --depth=1 https://github.com/tfutils/tfenv.git /home/opencode/.tfenv \
    && chown -R opencode:opencode /home/opencode/.tfenv \
    && ln -s /home/opencode/.tfenv/bin/* /usr/local/bin/
USER opencode
RUN tfenv install ${TERRAFORM_VERSION} \
    && tfenv use ${TERRAFORM_VERSION}
USER root

# =============================================================================
# Terraform Tools (installed system-wide as root)
# =============================================================================

# terraform-docs
ARG TERRAFORM_DOCS_VERSION=0.18.0
RUN curl -fsSL "https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-$(dpkg --print-architecture).tar.gz" \
    | tar -C /usr/local/bin -xzf - terraform-docs \
    && chmod +x /usr/local/bin/terraform-docs

# tflint
ARG TFLINT_VERSION=0.53.0
RUN curl -fsSL "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_$(dpkg --print-architecture).zip" -o /tmp/tflint.zip \
    && unzip /tmp/tflint.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/tflint \
    && rm /tmp/tflint.zip

# trivy (security scanner)
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# driftctl
ARG DRIFTCTL_VERSION=0.40.0
RUN curl -fsSL "https://github.com/snyk/driftctl/releases/download/v${DRIFTCTL_VERSION}/driftctl_linux_$(dpkg --print-architecture)" -o /usr/local/bin/driftctl \
    && chmod +x /usr/local/bin/driftctl

# =============================================================================
# yq (YAML processor)
# =============================================================================
ARG YQ_VERSION=4.44.3
RUN curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_$(dpkg --print-architecture)" -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# =============================================================================
# Python Tools (pre-commit, commitizen, boto3)
# =============================================================================
RUN pip3 install --break-system-packages --no-cache-dir \
    pre-commit \
    commitizen \
    boto3==1.40.15

# =============================================================================
# uv/uvx (Astral - for MCP servers) - installed for opencode user
# =============================================================================
USER opencode
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
USER root
ENV PATH="/home/opencode/.local/bin:${PATH}"

# =============================================================================
# OpenCode CLI (download glibc version for Ubuntu)
# =============================================================================
ARG OPENCODE_VERSION=1.1.51
RUN ARCH=$(dpkg --print-architecture | sed 's/amd64/x64/') \
    && curl -fsSL "https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/opencode-linux-${ARCH}.tar.gz" \
    | tar -C /usr/local/bin -xzf - \
    && chmod +x /usr/local/bin/opencode

# =============================================================================
# Playwright MCP (browser automation for testing)
# =============================================================================
# Ubuntu 24.04 only offers Chromium via snap, which doesn't work in Docker.
# Solution: Add Debian's repository to get real chromium packages for ARM64.
RUN apt-get update \
    && apt-get install -y --no-install-recommends debian-archive-keyring \
    && echo "deb [signed-by=/usr/share/keyrings/debian-archive-keyring.gpg] http://deb.debian.org/debian bookworm main" > /etc/apt/sources.list.d/debian.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends chromium \
    && rm -rf /var/lib/apt/lists/* \
    && rm /etc/apt/sources.list.d/debian.list

ENV PLAYWRIGHT_BROWSERS_PATH=/opt/playwright
ENV PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/lib/chromium/chromium
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
ARG PLAYWRIGHT_MCP_VERSION=0.0.64
RUN npm install -g @playwright/mcp@${PLAYWRIGHT_MCP_VERSION} \
    && mkdir -p /opt/playwright \
    && chown -R opencode:opencode /opt/playwright \
    && chmod -R 755 /opt/playwright

# =============================================================================
# GitHub CLI (for git credential helper)
# =============================================================================
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# Git Configuration (for opencode user)
# =============================================================================
# Safe directory wildcard allows git to work with mounted repos owned by different UID
USER opencode
RUN git config --global --add safe.directory '*' \
    && git config --global user.email "opencode@triafed.com" \
    && git config --global user.name "OpenCode"
USER root

# =============================================================================
# SSH Configuration (Network Lockdown)
# =============================================================================
# System-wide SSH config that routes SSH through egress-proxy and blocks
# all non-allowlisted hosts. Placed in /etc/ssh/ssh_config.d/ so it's
# owned by root and cannot be modified by the opencode user.
#
# NOTE: The "99-" prefix ensures this file is loaded LAST, so the
# "Host *" catch-all rule takes effect after any other configs.
RUN mkdir -p /etc/ssh/ssh_config.d
COPY ssh_config /etc/ssh/ssh_config.d/99-admiral-network-lockdown.conf
RUN chmod 644 /etc/ssh/ssh_config.d/99-admiral-network-lockdown.conf

# =============================================================================
# ctkey Compatibility Shim
# =============================================================================
# Existing local deploy scripts often call `eval $(ctkey setenv ...)`.
# We intentionally do not include real ctkey in the container. This shim only
# re-exports the already-present restricted AWS credentials.
COPY devops/scripts/ctkey-shim.sh /usr/local/bin/ctkey
RUN chmod 755 /usr/local/bin/ctkey

# =============================================================================
# Entrypoint Script
# =============================================================================
# Sets up gh auth from env vars before starting OpenCode
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY scripts/login-dev-workspace.js /opt/admiral-playwright/login-dev-workspace.js
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# =============================================================================
# Driftctl Environment Variables
# =============================================================================
ENV TF_SUPPRESS_PROVIDER_OVERRIDE_WARNINGS=1
ENV DCTL_FILTER=""
ENV DCTL_DEEP=false
ENV DCTL_QUIET=true
ENV DCTL_DRIFTIGNORE=".driftignore"
ENV DCTL_ONLY_UNMANAGED=false
ENV DCTL_NO_VERSION_CHECK=true
ENV DCTL_DISABLE_TELEMETRY=true

# =============================================================================
# AWS Environment Variables
# =============================================================================
ENV AWS_REGION=us-east-1
ENV AWS_DEFAULT_REGION=us-east-1
ENV AWS_DEFAULT_OUTPUT=json

# =============================================================================
# Shell Configuration (for opencode user)
# =============================================================================
# Source nvm in bashrc for interactive shells
RUN echo 'export NVM_DIR="/home/opencode/.nvm"' >> /home/opencode/.bashrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /home/opencode/.bashrc \
    && echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> /home/opencode/.bashrc \
    && chown opencode:opencode /home/opencode/.bashrc

# =============================================================================
# OpenCode Configuration (baked into image)
# =============================================================================
# Copy the OpenCode config file
RUN mkdir -p /home/opencode/.config/opencode \
    && chown -R opencode:opencode /home/opencode/.config
COPY --chown=opencode:opencode opencode.json /home/opencode/.config/opencode/opencode.json

# Copy .opencode directory (tools, commands, agents) to /opt and install dependencies
# This location won't be shadowed by the ~/admiral volume mount
# The entrypoint script will symlink this into the workspace
COPY .opencode /opt/admiral-opencode
RUN if [ -f /opt/admiral-opencode/package.json ]; then \
        cd /opt/admiral-opencode && npm install; \
    fi \
    && chown -R opencode:opencode /opt/admiral-opencode

# =============================================================================
# Create directories for opencode user
# =============================================================================
# Pre-create ALL directories that will be volume-mounted so they exist with
# correct ownership BEFORE Docker mounts volumes (otherwise Docker creates
# mount points as root). This is critical for non-root container operation.
RUN mkdir -p /home/opencode/admiral \
    && mkdir -p /home/opencode/.local/share/opencode/storage \
    && mkdir -p /home/opencode/.local/share/opencode/snapshot \
    && mkdir -p /home/opencode/.local/share/opencode/log \
    && mkdir -p /home/opencode/.local/share/opencode/exports \
    && mkdir -p /home/opencode/.local/share/opencode/tool-output \
    && mkdir -p /home/opencode/.local/share/opencode/bin \
    && mkdir -p /home/opencode/.cache/opencode \
    && mkdir -p /home/opencode/.local/state/opencode \
    && mkdir -p /home/opencode/go \
    && chown -R opencode:opencode /home/opencode

# =============================================================================
# Finalize - switch to non-root user
# =============================================================================
USER opencode
WORKDIR /home/opencode/admiral

# Default command (overridden by docker-compose)
CMD ["opencode", "serve", "--port", "4096", "--hostname", "0.0.0.0"]
