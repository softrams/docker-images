FROM alpine/ansible:3.21

RUN apk --no-cache add --update wget zip unzip python3 py3-pip bash aws-cli && \
    apk --no-cache --update add --virtual build-dependencies python3-dev && \
    rm /usr/lib/python3.12/EXTERNALLY-MANAGED && \
    pip3 install --upgrade cffi && \
    pip3 install ansible==11.1.0 && \
    pip3 install boto3 && \
    apk del build-dependencies
     
