FROM amazon/aws-cli:latest

RUN yum install -y \
    curl \
    git \
    gzip \
    jq \
    python3 \
    tar \
    wget \
    && yum -y clean all \
    && rm -rf /var/cache

RUN curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | bash && \
    curl -L https://raw.githubusercontent.com/warrensbox/tgswitch/release/install.sh | bash
