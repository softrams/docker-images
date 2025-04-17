FROM alpine/ansible:2.17.0

RUN apk upgrade --no-cache \ 
    apk --no-cache add python3 botocore boto3 aws-cli
RUN pip3 ugrade  && \
    ansible-galaxy collection install community.aws
     
