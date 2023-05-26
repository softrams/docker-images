FROM node:16.20

# Install Google Chrome
RUN apt-get update && \
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt install --assume-yes ./google-chrome-stable_current_amd64.deb &&\
    apt install --assume-yes zip rsync
RUN npm install -g typescript @angular/cli
