FROM alpine:3.4

RUN apk update && \
apk add --update python3 py3-pip \
rm -rf /tmp/* && \
rm -rf /var/cache/apk/* && \
apk add --no-cache openssh-client

RUN pip3 install ansible~=6.0.0
