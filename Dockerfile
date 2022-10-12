FROM alpine:3.15.0


ENV WORKSPACE="."
#install psql client
USER root
RUN apk add postgresql-client && apk add jq
