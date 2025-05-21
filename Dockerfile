FROM node:20.17

# Enable 32-bit architecture for Wine
RUN dpkg --add-architecture i386

# Install system dependencies for Wine + Chrome + Electron builds
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
    libxrandr2 \
    libcups2 \
    libpangocairo-1.0-0 \
    libappindicator3-1 \
    mono-complete \
    cabextract \
    unzip \
    wine64 \
    wine32 \
    winbind && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set Wine environment variables
ENV WINEARCH=win64
ENV WINEDLLOVERRIDES=mscoree=d;mshtml=d
ENV WINEPREFIX=/root/.wine64

# Install dependencies required by winetricks
RUN apt-get update && apt-get install -y \
  cabextract \
  unzip \
  p7zip-full \
  wget \
  gnupg2 \
  software-properties-common

# Install winetricks from GitHub
RUN wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -O /usr/local/bin/winetricks && \
    chmod +x /usr/local/bin/winetricks

RUN xvfb-run --auto-servernum --server-args='-screen 0 1024x768x16' winetricks -q dotnet48 corefonts msxml6 vcrun2015 || true

# Download Wine Mono and Gecko installers
RUN mkdir -p /opt/wine-installer && \
    cd /opt/wine-installer && \
    wget https://dl.winehq.org/wine/wine-mono/8.1.0/wine-mono-8.1.0-x86.msi && \
    wget https://dl.winehq.org/wine/wine-gecko/2.47.2/wine-gecko-2.47.2-x86.msi && \
    wget https://dl.winehq.org/wine/wine-gecko/2.47.2/wine-gecko-2.47.2-x86_64.msi

# Initialize Wine and install Mono and Gecko
RUN wineboot --init || true && \
    wine64 msiexec /i /opt/wine-installer/wine-mono-8.1.0-x86.msi /quiet || true && \
    wine64 msiexec /i /opt/wine-installer/wine-gecko-2.47.2-x86_64.msi /quiet || true && \
    wine msiexec /i /opt/wine-installer/wine-gecko-2.47.2-x86.msi /quiet || true

# Set environment variables for Xvfb and Wine
ENV DISPLAY=:99
ENV WINEDEBUG=-all
ENV WINEDLLOVERRIDES=mscoree=d

# Install Google Chrome
RUN wget -q -O /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    dpkg -i /tmp/google-chrome-stable_current_amd64.deb || apt-get -f install -y && \
    rm -f /tmp/google-chrome-stable_current_amd64.deb

# Install Node-based CLIs
RUN npm install -g @getgauge/cli mustache

# Start Xvfb when the container starts
CMD Xvfb :99 -screen 0 1024x768x16 & tail -f /dev/null
