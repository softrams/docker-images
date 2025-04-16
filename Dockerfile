FROM public.ecr.aws/docker/library/python:3.12
RUN pip3 install boto3 awscli requests
RUN yum install -y --setopt=obsoletes=false ansible \
    && yum clean all
