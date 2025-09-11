FROM node:22

RUN apt update &&\
    apt install zip git jq -y

# Install pip3, ansible, and awscli
RUN apt update && \
    apt install -y python3-pip && \
    pip3 install --upgrade pip --break-system-packages && \
    pip3 install ansible awscli --break-system-packages && \
    ansible --version && \
    aws --version

RUN npm install -g typescript
