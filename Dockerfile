FROM node:16.20

# Install Google Chrome
RUN apt-get update && \
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt install --assume-yes ./google-chrome-stable_current_amd64.deb &&\
    apt install --assume-yes zip rsync
RUN npm install -g typescript
RUN wget https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem && mv global-bundle.pem /usr/local/share/ca-certificates/aws.pem
