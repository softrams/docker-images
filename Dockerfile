FROM alpine:3.4

RUN apk update && \
apk add --no-cache python3-pip && \
rm -rf /tmp/* && \
rm -rf /var/cache/apk/* && \
apk add --no-cache openssh-client

RUN pip install ansible~=6.0.0
