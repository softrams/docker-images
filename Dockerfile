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

# Install GitHub CLI used by PR review and pre-commit reporting
RUN curl -fsSL https://github.com/cli/cli/releases/download/v2.40.0/gh_2.40.0_linux_amd64.tar.gz -o gh.tar.gz && \
    tar -xzf gh.tar.gz && \
    cp gh_2.40.0_linux_amd64/bin/gh /usr/local/bin/ && \
    chmod +x /usr/local/bin/gh && \
    rm -rf gh.tar.gz gh_2.40.0_linux_amd64

# Install Gauge CLI
RUN npm install -g @getgauge/cli

RUN  gauge install html-report --version 4.1.4 && \
     gauge install java --version 0.9.1 && \
     gauge install screenshot --version 0.1.0 && \
     gauge install js --version 2.4.0 && \
     gauge install json-report --version 0.3.7 && \
     gauge install ts --version 0.1.0

RUN export TAIKO_SKIP_CHROMIUM_DOWNLOAD=true && \
     npm install -g taiko


# Install AWS CLI
RUN apt update && \
    apt install python-dev-is-python3 python3-pip jq -y && \
    pip3 install awscli boto3 pre-commit==4.0.1 --break-system-packages && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Mustache is used by the UI pipeline to render its environment config
RUN npm install -g mustache
