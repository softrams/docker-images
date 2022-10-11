FROM node:12.20.2

# Install Google Chrome
RUN apt-get update && \
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt install --assume-yes ./google-chrome-stable_current_amd64.deb
