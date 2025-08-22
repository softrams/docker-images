# Extend existing terraform-ci image
FROM ghcr.io/softrams/docker-images:terraform-ci

# Metadata
LABEL maintainer="Softrams DevOps <devops@softrams.com>"
LABEL description="Terraform CI with enhanced security scanning"
LABEL version="1.0.0"

# Install Python and security tools
RUN apk add --no-cache \
    python3 \
    py3-pip \
    curl \
    wget

# Install Checkov for IaC security
RUN pip3 install --no-cache-dir checkov

# Install Trivy for Terraform scanning
RUN TRIVY_VERSION=$(curl -s https://api.github.com/repos/aquasecurity/trivy/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4) && \
    wget -O trivy.tar.gz "https://github.com/aquasecurity/trivy/releases/download/${TRIVY_VERSION}/trivy_${TRIVY_VERSION#v}_Linux-64bit.tar.gz" && \
    tar -xzf trivy.tar.gz && \
    mv trivy /usr/local/bin/ && \
    rm trivy.tar.gz

# Install tfsec (legacy support)
RUN TFSEC_VERSION=$(curl -s https://api.github.com/repos/aquasecurity/tfsec/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4) && \
    wget -O tfsec "https://github.com/aquasecurity/tfsec/releases/download/${TFSEC_VERSION}/tfsec-linux-amd64" && \
    chmod +x tfsec && \
    mv tfsec /usr/local/bin/

# Create Terraform security scan script
RUN echo '#!/bin/sh\n\
set -e\n\
echo "Running Checkov IaC security scan..."\n\
checkov -d . --framework terraform --output json --output-file checkov-results.json || true\n\
echo "Running Trivy Terraform scan..."\n\
trivy config . --format json --output trivy-terraform-results.json || true\n\
echo "Running tfsec scan..."\n\
tfsec . --format json --out tfsec-results.json || true\n\
echo "Terraform security scan completed"\n\
' > /usr/local/bin/terraform-security-scan.sh && \
    chmod +x /usr/local/bin/terraform-security-scan.sh

# Verify installations
RUN terraform version && \
    checkov --version && \
    trivy --version && \
    tfsec --version

# Default command
CMD ["/bin/sh"]
