FROM node:20.17

# Enable 32-bit architecture for Wine
RUN dpkg --add-architecture i386

# Install system dependencies for wine + Chrome + Electron builds
RUN apt-get update && apt-get install -y \
    software-properties-common \
    gnupg2 \
    wget \
    curl \
    ca-certificates \
    libgbm-dev \
    zip \
    rsync \
    fonts-liberation \
    xdg-utils \
    libasound2 \
    libnss3 \
    libxss1 \
    libgconf-2-4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libgtk-3-0 \
    libx11-xcb1 \
    xvfb \
    x11-utils \
    libxtst6 \
    libxss1 \
    libxrandr2 \
    libcups2 \
    libpangocairo-1.0-0 \
    libappindicator3-1 || apt-get install -y libayatana-appindicator3-1 && \
    apt-get clean

# Install Wine (32-bit + 64-bit)
RUN apt-get install -y wine64 wine32

# Verify wine works
RUN wine --version

# Install Google Chrome
RUN wget -q -O /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    dpkg -i /tmp/google-chrome-stable_current_amd64.deb || apt-get -f install -y && \
    rm -f /tmp/google-chrome-stable_current_amd64.deb

# Install Node-based CLIs
RUN npm install -g @getgauge/cli mustache

# Clean up
RUN rm -rf /var/lib/apt/lists/*
