FROM snyk/driftctl:v0.38.1

# Install the AWS CLI
RUN apk add --no-cache python3 py3-pip
RUN pip3 install --upgrade pip
RUN pip3 install awscli

# Install jq
RUN apk add --no-cache jq