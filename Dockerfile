FROM ghcr.io/softrams/docker-images:node-latest

# The Taiko installation downloads and installs the chromium required to run the tests.
# However, we need the chromium dependencies installed in the environment. These days, most
# Dockerfiles just install chrome to get the dependencies.
RUN apt-get update \
     && apt-get install -y wget gnupg ca-certificates vim \
     && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
     && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
     && apt-get update \
     && apt-get install -y google-chrome-stable

RUN cp /usr/share/zoneinfo/America/New_York /etc/localtime

# Set a custom npm install location so that Gauge, Taiko and dependencies can be
# installed without root privileges
ENV NPM_CONFIG_PREFIX=/home/gauge/.npm-packages
ENV PATH="${NPM_CONFIG_PREFIX}/bin:${PATH}"
ENV ENV_ARGS = "--verbose"

# Add the Taiko browser arguments
ENV TAIKO_BROWSER_ARGS=--no-sandbox,--start-maximized,--disable-dev-shm-usage
ENV headless_chrome=true
ENV TAIKO_SKIP_DOCUMENTATION=true

# Uncomment the lines below to use chrome bundled with this image
#ENV TAIKO_SKIP_CHROMIUM_DOWNLOAD=true
#ENV TAIKO_BROWSER_PATH=/usr/bin/google-chrome

# Set working directory
WORKDIR /gauge

# Install dependencies and plugins
RUN nodejs --version && \
    npm --version && \
    npm ci && \
    npx gauge install && \
    npx gauge config check_updates false

# Default command on running the image
CMD ["npm", "test"]
