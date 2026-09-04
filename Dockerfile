# node 22.23 + Google Chrome, for UI repo test suites (Karma/Puppeteer) in CI.
#
# Debian on purpose, not Alpine: Google publishes Chrome for Debian/Ubuntu only,
# and glibc is what the prebuilt binary links against.
#
# amd64 only. Google publishes no arm64 build of Chrome for Linux, so this image
# builds on linux/amd64 alone - which matches ci.yaml (ubuntu-latest). On an
# arm64 host, build with --platform linux/amd64.
FROM node:22.23.2-bookworm

# CHROME_BIN is what Karma reads to launch ChromeHeadless.
# PUPPETEER_EXECUTABLE_PATH/SKIP_DOWNLOAD point puppeteer-based suites at this
# binary so they do not download their own copy at run time, which would need
# registry egress the CI/agent nodes may not have.
ENV CHROME_BIN=/usr/bin/google-chrome \
    CHROME_PATH=/usr/bin/google-chrome \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome \
    PUPPETEER_SKIP_DOWNLOAD=true \
    PATH=/opt/aws/bin:$PATH

# Installed from Google's apt repo rather than a standalone .deb so apt resolves
# the font and graphics dependencies itself, instead of the
# `dpkg -i || apt-get -f install` two-step. --no-install-recommends is safe here:
# everything Chrome actually needs (fonts-liberation, libasound2, libatk*, libnss3,
# libgbm1, xdg-utils, ...) is a hard Depends, not a Recommends.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl gnupg; \
    install -m 0755 -d /etc/apt/keyrings; \
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
      | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg; \
    chmod a+r /etc/apt/keyrings/google-chrome.gpg; \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
      > /etc/apt/sources.list.d/google-chrome.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends google-chrome-stable; \
    rm -rf /var/lib/apt/lists/*

# boto3 + awscli. The base image ships no pip, and Debian 12's python3 is
# PEP 668 externally-managed, so a bare `pip install` cannot work here. A venv
# carries no EXTERNALLY-MANAGED marker, so this needs no --break-system-packages.
#
# /opt/aws/bin goes on PATH (above), so `python3`, `pip` and `aws` all resolve to
# the venv. That keeps the behaviour a global `pip install` was after: `import
# boto3` works from a plain `python3 script.py`, with no venv activation step.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends python3 python3-venv; \
    rm -rf /var/lib/apt/lists/*; \
    python3 -m venv /opt/aws; \
    /opt/aws/bin/pip install --no-cache-dir --upgrade pip; \
    /opt/aws/bin/pip install --no-cache-dir boto3 awscli

# Fail the build here, loudly, rather than several stages into a CI run.
RUN set -eux; \
    node --version; \
    npm --version; \
    google-chrome --version; \
    google-chrome --headless --no-sandbox --disable-gpu --dump-dom about:blank > /dev/null; \
    python3 --version; \
    aws --version; \
    python3 -c "import boto3; print('boto3', boto3.__version__)"
