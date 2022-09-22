FROM alpine:3.14
ENV USER=ansible
ENV UID=1000
ENV GID=1000
USER root

RUN apk update && \
apk add --no-cache ansible && \
rm -rf /tmp/* && \
rm -rf /var/cache/apk/* && \
apk add --no-cache curl 
RUN addgroup --system -g "$GID" -S "${USER}" 
RUN adduser --system -h "$(pwd)/${USER}" -s /bin/ash -D -u "${UID}" -G "${USER}" "${USER}"
