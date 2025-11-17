FROM amazon/aws-cli:latest

RUN yum install -y wget \
    tar \
    gzip \
    git \
    jq \
    python3 \
    python3-pip \
    bash \
    && yum -y clean all \
    && rm -rf /var/cache

RUN pip3 install boto3

# Install GitHub CLI
COPY --from=maniator/gh:v2.63.0 /usr/bin/gh /usr/bin/gh
RUN chmod +x /usr/bin/gh && gh --version

RUN wget -O tfswitch https://github.com/warrensbox/terraform-switcher/releases/download/0.13.1308/terraform-switcher_0.13.1308_linux_amd64 \
    && chmod +x tfswitch \
    && mv tfswitch /usr/local/bin/tfswitch \
    && tfswitch --version
