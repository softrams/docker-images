FROM alpine:3.20

RUN apk update && \
apk add --no-cache ansible curl git && \
rm -rf /tmp/* && \
rm -rf /var/cache/apk/*

RUN wget https://releases.hashicorp.com/packer/1.11.2/packer_1.11.2_linux_amd64.zip &&\
  unzip packer_1.11.2_linux_amd64.zip &&\
  mv packer /usr/bin &&\
  rm packer_1.11.2_linux_amd64.zip &&\
  packer plugins install github.com/hashicorp/amazon &&\
  packer plugins install github.com/hashicorp/ansible
