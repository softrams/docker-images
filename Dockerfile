FROM public.ecr.aws/docker/library/python:3.11.6-alpine
RUN pip install boto3 awscli requests
RUN 'python3 -m pip install --user ansible && \
    python3 -m pip install --user ansible-core'
