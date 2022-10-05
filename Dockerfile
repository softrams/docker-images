FROM amazon/aws-cli:latest

RUN yum install -y wget \
    tar \
    gzip \
    git \
    jq \
    python3 \
    && yum -y clean all \
    && rm -rf /var/cache

RUN wget -N -c https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh \
    && chmod 755 install.sh \
    && ./install.sh