FROM node:20.2.0

# Install Google Chrome
RUN apt-get update && \
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt install --assume-yes \
    libgbm-dev \
    zip \
    rsync \
    ./google-chrome-stable_current_amd64.deb &&\
    rm google-chrome-stable_current_amd64.deb &&\
    npm install -g @getgauge/cli


