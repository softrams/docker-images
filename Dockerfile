FROM snyk/driftctl:v0.39.0

RUN apk add py3-pip --no-cache
RUN pip install boto3
