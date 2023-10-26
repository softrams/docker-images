FROM public.ecr.aws/docker/library/python:3.11.6-alpine
RUN pip install boto3 awscli
