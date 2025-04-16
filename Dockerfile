FROM alpine/ansible:2.17.0

RUN apk add --no-cache aws-cli
RUN ansible-galaxy collection install community.aws
