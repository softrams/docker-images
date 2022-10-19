FROM python:3.10.8-alpine3.16

RUN apk add --no-cache --virtual jsonlint \
    && pip3 install simplejson
