FROM alpine:3.21

RUN apk --no-cache add --update jq wget zip unzip python3 py3-pip bash aws-cli curl krb5 && \
    apk --no-cache --update add --virtual build-dependencies python3-dev build-base libffi-dev openssl-dev && \
    apk --no-cache add jq && \
    rm /usr/lib/python3.12/EXTERNALLY-MANAGED && \
    pip3 install --upgrade pip cffi && \
    pip3 install ansible==9.1.0 boto3 hvac pywinrm requests-credssp && \
    apk del build-dependencies

# Install GitHub CLI (gh)
RUN wget -q https://github.com/cli/cli/releases/download/v2.51.0/gh_2.51.0_linux_amd64.tar.gz && \
    tar -xzf gh_2.51.0_linux_amd64.tar.gz && \
    mv gh_2.51.0_linux_amd64/bin/gh /usr/local/bin/ && \
    rm -rf gh_2.51.0_linux_amd64* && \
    gh --version

# Install HashiCorp Vault CLI
RUN wget -q https://releases.hashicorp.com/vault/1.18.3/vault_1.18.3_linux_amd64.zip && \
    unzip vault_1.18.3_linux_amd64.zip && \
    mv vault /usr/local/bin/ && \
    rm vault_1.18.3_linux_amd64.zip && \
    vault --version
