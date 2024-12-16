# Building the image
# 	docker build -t gauge-taiko .
# Running the image
# 	docker run  --rm -it -v ${PWD}/reports:/gauge/reports gauge-taiko

# This image uses the official node base image.
FROM node:18

# The Taiko installation downloads and installs the chromium required to run the tests.
# However, we need the chromium dependencies installed in the environment. These days, most
# Dockerfiles just install chrome to get the dependencies.
RUN apt-get update \
     && apt-get install -y wget gnupg ca-certificates vim \
     && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
     && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
     && apt-get update \
     && apt-get install -y google-chrome-stable \
     && apt-get install -y unzip

# Install Oracle Client
RUN mkdir -p /opt/oracle && \
    cd /opt/oracle && \
    wget https://download.oracle.com/otn_software/linux/instantclient/214000/instantclient-basic-linux.x64-21.4.0.0.0dbru.zip && \
    unzip instantclient-basic-linux.x64-21.4.0.0.0dbru.zip && \
    apt-get install -y libaio1 && \
    sh -c "echo /opt/oracle/instantclient_21_4 > /etc/ld.so.conf.d/oracle-instantclient.conf" && \
    ldconfig

# Set a custom npm install location so that Gauge, Taiko and dependencies can be
# installed without root privileges
ENV NPM_CONFIG_PREFIX=/home/gauge/.npm-packages
ENV PATH="${NPM_CONFIG_PREFIX}/bin:${PATH}"

# Add the Taiko browser arguments
ENV TAIKO_BROWSER_ARGS=--no-sandbox,--start-maximized,--disable-dev-shm-usage
ENV headless_chrome=true
ENV TAIKO_SKIP_DOCUMENTATION=true

# Set working directory
WORKDIR /gauge

# Create an unprivileged user to run Taiko tests
RUN groupadd -r gauge && useradd -r -g gauge -G audio,video gauge && \
   mkdir -p /home/gauge/.npm-packages/lib && \
   chown -R gauge:gauge /home/gauge /gauge

USER gauge

RUN npm install -g @getgauge/cli \
    && gauge install screenshot \
    && gauge config check_updates false

