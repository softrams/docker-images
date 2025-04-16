FROM amazon/aws-cli:latest

RUN yum install -y jq epel-release ansible && \
	yum clean all && \
    rm -rf /var/cache/yum
