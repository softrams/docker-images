FROM amazon/aws-cli:latest

RUN yum install -y jq && \
	yum clean all && \
    rm -rf /var/cache/yum
