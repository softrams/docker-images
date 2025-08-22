FROM node:18-alpine

# Metadata
LABEL maintainer="Softrams DevOps <devops@softrams.com>"
LABEL description="Node.js 18 with security scanning tools"
LABEL version="1.0.0"

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    wget \
    python3 \
    py3-pip \
    build-base \
    ca-certificates

# Install global npm security packages
RUN npm install -g \
    eslint \
    eslint-plugin-security \
    eslint-plugin-node \
    retire \
    npm-audit-resolver \
    audit-ci \
    yarn \
    pnpm

# Install Python security tools
RUN pip3 install --no-cache-dir \
    bandit \
    safety

# Create security scripts directory
RUN mkdir -p /opt/security-scripts

# Create audit wrapper script
RUN echo '#!/bin/sh\n\
set -e\n\
echo "Running npm audit..."\n\
npm audit --audit-level moderate || true\n\
echo "Running retire.js..."\n\
retire --path . || true\n\
echo "Node.js security scan completed"\n\
' > /opt/security-scripts/node-security-scan.sh && \
    chmod +x /opt/security-scripts/node-security-scan.sh

# Add to PATH
ENV PATH="/opt/security-scripts:${PATH}"

# Set working directory
WORKDIR /workspace

# Verify installations
RUN node --version && \
    npm --version && \
    eslint --version && \
    retire --version

# Default command
CMD ["/bin/sh"]
