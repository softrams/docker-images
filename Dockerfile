FROM ubuntu:22.04

# Metadata
LABEL maintainer="Softrams DevOps <devops@softrams.com>"
LABEL description="Multi-language development with comprehensive security tools"
LABEL version="1.0.0"

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV NODE_VERSION=18.x
ENV GO_VERSION=1.21.5
ENV JAVA_VERSION=17
ENV DOTNET_VERSION=8.0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    jq \
    build-essential \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.11
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y python3.11 python3.11-pip python3.11-venv && \
    ln -sf /usr/bin/python3.11 /usr/bin/python3 && \
    ln -sf /usr/bin/python3.11 /usr/bin/python && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js 18
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Go
RUN wget "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz" && \
    tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz" && \
    rm "go${GO_VERSION}.linux-amd64.tar.gz"

# Install Java 17
RUN apt-get update && \
    apt-get install -y openjdk-17-jdk && \
    rm -rf /var/lib/apt/lists/*

# Install .NET 8
RUN wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y dotnet-sdk-8.0 && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables for Go
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOROOT="/usr/local/go"
ENV GOPATH="/go"

# Install Python security tools
RUN python3 -m pip install --no-cache-dir \
    bandit \
    safety \
    pip-audit \
    semgrep

# Install Node.js security tools
RUN npm install -g \
    eslint \
    eslint-plugin-security \
    retire \
    audit-ci

# Install Semgrep (multi-language)
RUN python3 -m pip install --no-cache-dir semgrep

# Install language-specific security scanners
RUN go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest

# Create universal security scan script
RUN mkdir -p /opt/security-scripts && \
    echo '#!/bin/bash\n\
set -e\n\
echo "Running multi-language security scan..."\n\
\n\
# Python\n\
if find . -name "*.py" | head -1 | grep -q .; then\n\
    echo "Scanning Python files..."\n\
    bandit -r . -f json -o bandit-results.json || true\n\
    safety check --json --output safety-results.json || true\n\
fi\n\
\n\
# JavaScript/TypeScript\n\
if find . -name "*.js" -o -name "*.ts" | head -1 | grep -q .; then\n\
    echo "Scanning JavaScript/TypeScript files..."\n\
    if [ -f "package.json" ]; then\n\
        npm audit --audit-level moderate --json > npm-audit-results.json || true\n\
    fi\n\
    retire --path . --outputformat json --outputpath retire-results.json || true\n\
fi\n\
\n\
# Go\n\
if find . -name "*.go" | head -1 | grep -q .; then\n\
    echo "Scanning Go files..."\n\
    gosec -fmt json -out gosec-results.json ./... || true\n\
fi\n\
\n\
# Multi-language with Semgrep\n\
echo "Running Semgrep multi-language scan..."\n\
semgrep --config=auto --json --output=semgrep-results.json . || true\n\
\n\
echo "Multi-language security scan completed"\n\
' > /opt/security-scripts/multi-lang-security-scan.sh && \
    chmod +x /opt/security-scripts/multi-lang-security-scan.sh

# Add to PATH
ENV PATH="/opt/security-scripts:/go/bin:${PATH}"

# Set working directory
WORKDIR /workspace

# Verify installations
RUN python3 --version && \
    node --version && \
    go version && \
    java -version && \
    dotnet --version && \
    semgrep --version

# Default command
CMD ["/bin/bash"]
