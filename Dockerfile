FROM node:20.17

# Install required dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    libgbm-dev \
    zip \
    rsync \
    jinja-cli \
    fonts-liberation \
    libappindicator3-1 \
    xdg-utils \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome properly
RUN wget -q -O /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt-get update && \
    apt-get install -y ./tmp/google-chrome-stable_current_amd64.deb || apt-get -fy install && \
    rm -f /tmp/google-chrome-stable_current_amd64.deb

# Install Gauge CLI
RUN npm install -g @getgauge/cli



