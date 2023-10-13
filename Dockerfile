FROM snyk/driftctl:v0.39.0

RUN apk add py3-boto3 --no-cache
