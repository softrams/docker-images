FROM node:22.16.0

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
    python \
    libappindicator3-1 || apt-get install -y libayatana-appindicator3-1 \
    && apt-get clean

# Install Google Chrome with proper dependency handling
RUN wget -q -O /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt-get update && \
    dpkg -i /tmp/google-chrome-stable_current_amd64.deb || apt-get -f install -y && \
    rm -f /tmp/google-chrome-stable_current_amd64.deb

# Install Gauge CLI
RUN npm install -g @getgauge/cli

# Install OpenJDK (Java)
RUN apt-get update && apt-get install -y openjdk-17-jre-headless && java -version

RUN  gauge install html-report --version 4.4.0 && \
     gauge install java --version 1.0.1 && \
     gauge install screenshot --version 0.1.0 && \
     gauge install js --version 5.0.1 && \
     gauge install json-report --version 0.5.3 && \
     gauge install ts --version 0.1.0 && \
     gauge install flash --version 0.0.2

RUN export TAIKO_SKIP_CHROMIUM_DOWNLOAD=true && \
     npm install -g taiko


# Install AWS CLI and jq
RUN apt-get update && \
    apt-get install -y python-dev-is-python3 python3-pip jq && \
    pip3 install awscli --break-system-packages && \
    jq --version  