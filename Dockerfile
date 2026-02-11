FROM node:20.19.6

# Enable 32-bit architecture for Wine
RUN dpkg --add-architecture i386

# Install base dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    gnupg2 \
    wget \
    curl \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Add WineHQ repository for Debian Bookworm
RUN mkdir -pm755 /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources

# Install Wine and other system dependencies
RUN apt-get update && apt-get install -y \
    libgbm-dev \
    zip \
    rsync \
    fonts-liberation \
    xdg-utils \
    libasound2 \
    libnss3 \
    libxss1 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libgtk-3-0 \
    libx11-xcb1 \
    xvfb \
    x11-utils \
    libxtst6 \
    libxrandr2 \
    libcups2 \
    libpangocairo-1.0-0 \
    cabextract \
    unzip \
    p7zip-full \
    --install-recommends winehq-stable \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set Wine environment variables
ENV WINEARCH=win64
ENV WINEDLLOVERRIDES=mscoree=d;mshtml=d
ENV WINEPREFIX=/root/.wine64
ENV DISPLAY=:99
ENV WINEDEBUG=-all

# Install winetricks from GitHub
RUN wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -O /usr/local/bin/winetricks && \
    chmod +x /usr/local/bin/winetricks

# Initialize Wine and install .NET Framework
RUN xvfb-run --auto-servernum --server-args='-screen 0 1024x768x16' winetricks -q dotnet48 corefonts vcrun2015 || true

# Install Google Chrome with proper dependencies
RUN apt-get update && apt-get install -y \
    libu2f-udev \
    libvulkan1 \
    && wget -q -O /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && dpkg -i /tmp/google-chrome-stable_current_amd64.deb || apt-get -f install -y \
    && rm -f /tmp/google-chrome-stable_current_amd64.deb \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set Chrome binary path for Karma
ENV CHROME_BIN=/usr/bin/google-chrome

# Install Node-based CLIs
RUN npm install -g @getgauge/cli mustache

# Start Xvfb when the container starts
CMD Xvfb :99 -screen 0 1024x768x16 & tail -f /dev/null
