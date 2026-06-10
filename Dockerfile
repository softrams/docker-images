FROM mcr.microsoft.com/playwright:v1.60.0-noble

ARG GH_CLI_VERSION=2.76.0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    jq \
    wget \
    unzip \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI (architecture-aware)
RUN ARCH=$(dpkg --print-architecture) && \
    wget https://github.com/cli/cli/releases/download/v${GH_CLI_VERSION}/gh_${GH_CLI_VERSION}_linux_${ARCH}.deb && \
    apt-get update && apt-get install -y ./gh_${GH_CLI_VERSION}_linux_${ARCH}.deb && \
    rm gh_${GH_CLI_VERSION}_linux_${ARCH}.deb && \
    rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2 (architecture-aware)
RUN ARCH=$(uname -m) && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# Install Playwright browsers (already included in base image, but ensure latest)
RUN npx playwright install --with-deps

# Set environment to run Chromium in container
ENV CI=true
