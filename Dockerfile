FROM public.ecr.aws/docker/library/python:3.12
RUN pip3 install boto3 awscli requests
RUN 'apk add ansible'
