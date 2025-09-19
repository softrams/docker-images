FROM node:22

RUN apt update &&\
    apt install zip git jq -y

# Install pip3, ansible, and awscli
RUN apt update && \
    apt install -y python3-pip && \
    pip3 install --upgrade pip --break-system-packages && \
    pip3 install ansible==2.10.7 awscli --break-system-packages && \
    ansible --version && \
    aws --version

# Install boto3 and botocore for Ansible AWS modules
RUN pip3 install boto3 botocore --break-system-packages

RUN npm install -g typescript

# Install Google Chrome with proper dependency handling
RUN wget -q -O /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt-get update && \
    dpkg -i /tmp/google-chrome-stable_current_amd64.deb || apt-get -f install -y && \
    rm -f /tmp/google-chrome-stable_current_amd64.deb
