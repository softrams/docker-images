FROM python:3.11-slim

# Metadata
LABEL maintainer="Softrams DevOps <devops@softrams.com>"
LABEL description="Python 3.11 with security scanning tools"
LABEL version="1.0.0"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install security tools
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    bandit[toml] \
    safety \
    pip-audit \
    semgrep \
    pipenv \
    poetry \
    flake8 \
    flake8-bandit \
    flake8-bugbear \
    pep8-naming \
    requests \
    pyyaml

# Create security scripts directory
RUN mkdir -p /opt/security-scripts

# Create Python security scan script
RUN echo '#!/bin/bash\n\
set -e\n\
echo "Running Bandit security scan..."\n\
bandit -r . -f json -o bandit-results.json || true\n\
echo "Running Safety vulnerability check..."\n\
safety check --json --output safety-results.json || true\n\
echo "Running pip-audit..."\n\
pip-audit --format=json --output=pip-audit-results.json || true\n\
echo "Python security scan completed"\n\
' > /opt/security-scripts/python-security-scan.sh && \
    chmod +x /opt/security-scripts/python-security-scan.sh

# Add to PATH
ENV PATH="/opt/security-scripts:${PATH}"

# Set working directory
WORKDIR /workspace

# Verify installations
RUN python --version && \
    pip --version && \
    bandit --version && \
    safety --version && \
    pip-audit --version

# Default command
CMD ["/bin/bash"]
