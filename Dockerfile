FROM alpine/ansible:2.17.0

RUN apk add python3
RUN apk add --no-cache aws-cli \
    && ansible-galaxy collection install community.aws \
    && ANSIBLE_PYTHON_INTERPRETER=/usr/bin/python3.12 ansible localhost -m setup
