# Purpose-built agent image for ihpToolsSnykFixPipeline (ic-jenkins-library).
#
# Replaces the ghcr.io/softrams/docker-images:node-22.22.3 agent container, whose
# Setup stage had to apt-get git/python3 and bootstrap pip at runtime. The Jenkins
# nodes run a FIPS kernel, where libgcrypt aborts apt the moment it computes an MD5,
# so runtime provisioning is unreliable there by design. Everything the harness
# (resources/ic-ai-developer/agent-source-code/ai-developer.py) shells out to is
# baked in here instead, at build time, on a non-FIPS GitHub runner.
#
# Debian on purpose, not Alpine: the harness runs `npm ci` against real repos, and
# musl breaks dependencies shipping prebuilt glibc binaries or building via node-gyp.
#
# amd64 only. Google publishes no arm64 build of Chrome for Linux, so this image builds
# on linux/amd64 alone - which matches ci.yaml (ubuntu-latest) and the Jenkins pod. On
# an arm64 host, build with --platform linux/amd64.
FROM node:22.23.2-bookworm

# JDK 17 + Maven 3.9 to match maven:3-openjdk-17, the base the sibling IHP Java
# pipelines build with (ihpJavaPipeline.groovy, ihpJavaLibraryPipeline.groovy).
# Building the javaServices repos the same way their own CI does keeps the agent
# from green-lighting a fix that then fails in the repo's real pipeline.
ARG MAVEN_VERSION=3.9.9
ARG MAVEN_BASE_URL=https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries

# JAVA_HOME points at an arch-independent symlink created below. Debian installs the
# JDK to /usr/lib/jvm/java-17-openjdk-<arch>, so hardcoding -amd64 breaks any arm64
# build: java/javac still resolve via PATH, but Maven reads JAVA_HOME and refuses to
# start with "JAVA_HOME environment variable is not defined correctly".
ENV JAVA_HOME=/usr/lib/jvm/java-17 \
    MAVEN_HOME=/usr/share/maven \
    AI_DEV_PYTHON=/opt/ai-developer/bin/python3 \
    PYTHONUNBUFFERED=1 \
    CHROME_BIN=/usr/bin/google-chrome \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome \
    PUPPETEER_SKIP_DOWNLOAD=true

# A full JDK, not a JRE: the harness runs `mvn package` and `mvn test`, which compile.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        gnupg \
        jq \
        openjdk-17-jdk-headless \
        python3 \
        python3-pip \
        python3-venv \
        unzip \
        wget \
        zip \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s "$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")" "${JAVA_HOME}" \
    && test -x "${JAVA_HOME}/bin/javac"

# Google Chrome for the UI repos' test suites. The harness recognises karma.conf as an
# editable test config, and Karma launches ChromeHeadless via CHROME_BIN - without a
# browser here, `npm test` cannot validate a UI fix.
#
# Installed from Google's apt repo rather than a standalone .deb so apt resolves the
# font and graphics dependencies itself, instead of the `dpkg -i || apt-get -f install`
# two-step other branches use. PUPPETEER_EXECUTABLE_PATH/SKIP_DOWNLOAD (set above) point
# puppeteer-based suites at this binary so they do not pull their own copy at run time,
# which would need registry egress the Jenkins nodes may not have.
RUN set -eux; \
    install -m 0755 -d /etc/apt/keyrings; \
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
      | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg; \
    chmod a+r /etc/apt/keyrings/google-chrome.gpg; \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
      > /etc/apt/sources.list.d/google-chrome.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends google-chrome-stable; \
    rm -rf /var/lib/apt/lists/*

# Pinned tarball rather than Debian's maven package, so the Maven version is ours to
# control and matches the sibling pipelines. Verified against Apache's published sha512.
RUN set -eux; \
    curl -fsSL -o /tmp/apache-maven.tar.gz "${MAVEN_BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz"; \
    curl -fsSL -o /tmp/apache-maven.tar.gz.sha512 "${MAVEN_BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz.sha512"; \
    echo "$(cat /tmp/apache-maven.tar.gz.sha512)  /tmp/apache-maven.tar.gz" | sha512sum -c -; \
    mkdir -p "${MAVEN_HOME}"; \
    tar -xzf /tmp/apache-maven.tar.gz -C "${MAVEN_HOME}" --strip-components=1; \
    ln -s "${MAVEN_HOME}/bin/mvn" /usr/bin/mvn; \
    rm -f /tmp/apache-maven.tar.gz /tmp/apache-maven.tar.gz.sha512

# The harness interpreter. Kept at the /opt/ai-developer path the pipeline's Setup
# stage already builds and exports as AI_DEV_PYTHON, so the pipeline change is a
# deletion rather than a rewrite. A venv carries no EXTERNALLY-MANAGED marker, so
# none of this needs --break-system-packages.
#
# boto3 -> Bedrock. requests -> the Snyk and GitHub REST APIs; the harness calls both
# over HTTP, so neither the snyk CLI nor the gh CLI is needed here.
RUN python3 -m venv /opt/ai-developer \
    && /opt/ai-developer/bin/pip install --no-cache-dir --upgrade pip \
    && /opt/ai-developer/bin/pip install --no-cache-dir boto3 requests

# pnpm for repos that use it; the harness dispatches on the lockfile. Installed as a
# real global package, NOT via `corepack enable`: corepack only lays down shims that
# fetch the package manager from the registry on first use, and it would also replace
# the working yarn 1.22.22 the base image already ships. Both would then need registry
# egress at run time - the exact failure this image exists to remove.
ARG PNPM_VERSION=11.25.0
RUN npm install -g "pnpm@${PNPM_VERSION}" && npm cache clean --force

# Fail the build here, loudly, rather than several stages into a Jenkins run.
RUN set -eux; \
    git --version; \
    node --version; \
    npm --version; \
    java -version; \
    javac -version; \
    test -x "${JAVA_HOME}/bin/javac"; \
    mvn -v; \
    yarn --version; \
    pnpm --version; \
    google-chrome --version; \
    google-chrome --headless --no-sandbox --disable-gpu --dump-dom about:blank > /dev/null; \
    "${AI_DEV_PYTHON}" --version; \
    "${AI_DEV_PYTHON}" -c "import boto3, requests; print('boto3', boto3.__version__, '| requests', requests.__version__)"

WORKDIR /workspace
