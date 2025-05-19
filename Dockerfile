FROM node:20.17

# Install dependencies, including Wine prerequisites
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y \
    wget \
    curl \
    libgbm-dev \
    zip \
    rsync \
    fonts-liberation \
    xdg-utils \
    libasound2 \
    libappindicator3-1 \
    libnss3 \
    libxss1 \
    libgtk-3-0 \
    libgconf-2-4 \
    libnotify-dev \
    libxtst6 \
    xauth \
    x11-xkb-utils \
    xfonts-base \
    xfonts-75dpi \
    xfonts-100dpi \
    xfonts-cyrillic \
    wine64 \
    wine32 || apt-get install -y libayatana-appindicator3-1 && \
    apt-get clean

# Install Google Chrome with proper dependency handling
RUN wget -q -O /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt-get update && \
    dpkg -i /tmp/google-chrome-stable_current_amd64.deb || apt-get -f install -y && \
    rm -f /tmp/google-chrome-stable_current_amd64.deb

# Install Gauge CLI
RUN npm install -g @getgauge/cli

# Install Mustache CLI
RUN npm install -g mustache

# Clean up
RUN rm -rf /var/lib/apt/lists/*
