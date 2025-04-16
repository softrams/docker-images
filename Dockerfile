FROM alpine/ansible:2.17.0

# Install python/pip
ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3 py3-pip py3-boto3 aws-cli && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools
