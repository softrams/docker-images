FROM alpine:3.21

RUN apk --no-cache add --update jq wget zip unzip python3 py3-pip bash aws-cli curl krb5 && \
    apk --no-cache --update add --virtual build-dependencies python3-dev build-base libffi-dev openssl-dev && \
    rm /usr/lib/python3.12/EXTERNALLY-MANAGED && \
    pip3 install --upgrade pip cffi && \
    pip3 install ansible==9.1.0 boto3 hvac pywinrm requests-credssp && \
    apk del build-dependencies
    
RUN wget https://releases.hashicorp.com/packer/1.11.2/packer_1.11.2_linux_amd64.zip &&\
  unzip packer_1.11.2_linux_amd64.zip &&\
  mv packer /usr/bin &&\
  rm packer_1.11.2_linux_amd64.zip &&\
  packer plugins install github.com/hashicorp/amazon &&\
  packer plugins install github.com/hashicorp/ansible
