FROM amazon/aws-cli:latest

RUN yum install -y jq zip && \
	yum clean all && \
    rm -rf /var/cache/yum
