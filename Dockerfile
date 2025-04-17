FROM alpine/ansible:latest

RUN apk upgrade --no-cache && \ 
    apk add --no-cache py3-botocore py3-boto3 aws-cli
RUN ansible-galaxy collection install community.aws
     
