FROM node:20.17

# Ensure dependencies are installed before Chrome
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    libgbm-dev \
    zip \
    rsync \
    fonts-liberation \
    xdg-utils \
    libasound2 \
    libappindicator3-1 || apt-get install -y libayatana-appindicator3-1 \
    && apt-get clean

# Install Google Chrome with proper dependency handling
RUN wget -q -O /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt-get update && \
    dpkg -i /tmp/google-chrome-stable_current_amd64.deb || apt-get -f install -y && \
    rm -f /tmp/google-chrome-stable_current_amd64.deb

# Install GitHub CLI
RUN curl -fsSL https://github.com/cli/cli/releases/download/v2.40.0/gh_2.40.0_linux_amd64.tar.gz -o gh.tar.gz && \
    tar -xzf gh.tar.gz && \
    cp gh_2.40.0_linux_amd64/bin/gh /usr/local/bin/ && \
    chmod +x /usr/local/bin/gh && \
    rm -rf gh.tar.gz gh_2.40.0_linux_amd64

# Install Python and boto3
RUN apt-get update && apt-get install -y python3 python3-pip && \
    pip3 install boto3 --break-system-packages && \
    apt-get clean

# Install Gauge CLI
RUN npm install -g @getgauge/cli

# Install Mustache CLI
RUN npm install -g mustache

# Clean up
RUN rm -rf /var/lib/apt/lists/*
