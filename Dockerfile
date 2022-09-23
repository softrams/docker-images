FROM alpine:3.4

RUN apk update && \
apk add --no-cache ansible && \
rm -rf /tmp/* && \
rm -rf /var/cache/apk/* && \
apk add --no-cache curl && \
apk add --no-cache openssh-client
