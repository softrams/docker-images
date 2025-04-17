FROM alpine/ansible:2.17.0

RUN apk upgrade --no-cache && \ 
    apk add --no-cache python3 py3-botocore py3-boto3 aws-cli
RUN pip ugrade  && \
    ansible-galaxy collection install community.aws
     
