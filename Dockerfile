FROM amazon/aws-cli:latest

RUN yum install -y jq && \
	yum clean all && \
    rm -rf /var/cache/yum && \
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod u+x kubectl && mv kubectl /bin/kubectl 
