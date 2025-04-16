FROM amazon/aws-cli:latest

RUN yum install -y jq && \
    yum install epel-release && \
    yum install -y ansible && \
    yum clean all && \
    rm -rf /var/cache/yum
