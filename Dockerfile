FROM node:20.17

# Ensure the system is updated
RUN apt-get update && apt-get upgrade -y

# Install required system dependencies
RUN apt-get install -y \
    wget \
    curl \
    libgbm-dev \
    zip \
    rsync \
    fonts-liberation \
    xdg-utils \
    libasound2 \
    libappindicator3-1 \
    libayatana-appindicator3-1 \
    python3 \
    python3-pip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Jinja CLI via pip
RUN pip3 install --no-cache-dir jinja-cli

# Install Google Chrome with proper dependency handling
RUN wget -q -O /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt-get update && \
    dpkg -i /tmp/google-chrome-stable_current_amd64.deb || apt-get -f install -y && \
    rm -f /tmp/google-chrome-stable_current_amd64.deb

# Install Gauge CLI
RUN npm install -g @getgauge/cli

# Clean up
RUN rm -rf /var/lib/apt/lists/*




