FROM alpine:3.16

RUN apk update && \
apk add ansible && \
rm -rf /tmp/* && \
rm -rf /var/cache/apk/* && \
apk add --no-cache openssh-client


