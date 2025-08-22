FROM ubuntu:22.04

# Metadata
LABEL maintainer="Softrams DevOps <devops@softrams.com>"
LABEL description="Comprehensive security scanning suite for Jenkins pipelines"
LABEL version="1.0.0"

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PATH="/opt/security-tools/bin:${PATH}"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    jq \
    python3 \
    python3-pip \
    python3-venv \
    build-essential \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Create security tools directory
RUN mkdir -p /opt/security-tools/bin

# Install Gitleaks
RUN GITLEAKS_VERSION=$(curl -s https://api.github.com/repos/gitleaks/gitleaks/releases/latest | jq -r .tag_name) && \
    wget -O gitleaks.tar.gz "https://github.com/gitleaks/gitleaks/releases/download/${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION#v}_linux_x64.tar.gz" && \
    tar -xzf gitleaks.tar.gz && \
    mv gitleaks /opt/security-tools/bin/ && \
    rm gitleaks.tar.gz

# Install Trivy
RUN TRIVY_VERSION=$(curl -s https://api.github.com/repos/aquasecurity/trivy/releases/latest | jq -r .tag_name) && \
    wget -O trivy.tar.gz "https://github.com/aquasecurity/trivy/releases/download/${TRIVY_VERSION}/trivy_${TRIVY_VERSION#v}_Linux-64bit.tar.gz" && \
    tar -xzf trivy.tar.gz && \
    mv trivy /opt/security-tools/bin/ && \
    rm trivy.tar.gz

# Install TruffleHog
RUN TRUFFLEHOG_VERSION=$(curl -s https://api.github.com/repos/trufflesecurity/trufflehog/releases/latest | jq -r .tag_name) && \
    wget -O trufflehog.tar.gz "https://github.com/trufflesecurity/trufflehog/releases/download/${TRUFFLEHOG_VERSION}/trufflehog_${TRUFFLEHOG_VERSION#v}_linux_amd64.tar.gz" && \
    tar -xzf trufflehog.tar.gz && \
    mv trufflehog /opt/security-tools/bin/ && \
    rm trufflehog.tar.gz

# Install Grype
RUN GRYPE_VERSION=$(curl -s https://api.github.com/repos/anchore/grype/releases/latest | jq -r .tag_name) && \
    wget -O grype.tar.gz "https://github.com/anchore/grype/releases/download/${GRYPE_VERSION}/grype_${GRYPE_VERSION#v}_linux_amd64.tar.gz" && \
    tar -xzf grype.tar.gz && \
    mv grype /opt/security-tools/bin/ && \
    rm grype.tar.gz

# Install OSV Scanner
RUN OSV_VERSION=$(curl -s https://api.github.com/repos/google/osv-scanner/releases/latest | jq -r .tag_name) && \
    wget -O osv-scanner "https://github.com/google/osv-scanner/releases/download/${OSV_VERSION}/osv-scanner_linux_amd64" && \
    chmod +x osv-scanner && \
    mv osv-scanner /opt/security-tools/bin/

# Install Checkov
RUN pip3 install --no-cache-dir checkov

# Install Semgrep
RUN pip3 install --no-cache-dir semgrep

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Install additional Python security libraries
RUN pip3 install --no-cache-dir \
    bandit \
    safety \
    pip-audit \
    requests \
    pyyaml

# Create non-root user for security
RUN useradd -m -s /bin/bash scanner && \
    chown -R scanner:scanner /opt/security-tools

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER scanner

# Verify installations
RUN gitleaks version && \
    trivy --version && \
    trufflehog --version && \
    grype version && \
    osv-scanner --version && \
    checkov --version && \
    semgrep --version && \
    gh --version

# Default command
CMD ["/bin/bash"]
