FROM node:22-alpine
USER root
#  This installs open-java-1.8, Jenkins-slave, Node12, Chromium,


ARG VERSION=3.35
ARG user=jenkins
ARG group=jenkins
ARG uid=9000
ARG gid=9000
ARG AGENT_WORKDIR=/home/${user}/agent

COPY files/jenkins-agent /usr/local/bin/jenkins-agent

ADD files/xvfb-chromium /usr/bin/xvfb-chromium

RUN mkdir /var/lib/jenkins \
    && addgroup -g ${gid} ${group} \
    && adduser -h /home/${user} -u ${uid} -G ${group} -D ${user} \
    && set -x \
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk --no-cache  update \
    && apk --no-cache  upgrade \
    && apk add --no-cache gcc musl-dev python3-dev \
    && apk add --no-cache libtool \
    openjdk11 \
    libintl \
    python3 \
    git \
    py-setuptools \
    ansible \
    jq \
    make g++\
    unzip curl sed \
    zip \
    gifsicle pngquant optipng libjpeg-turbo-utils udev ttf-opensans chromium ca-certificates \
    bash git git-lfs openssh-client openssl procps xvfb fluxbox rsync \
    && python3 -m ensurepip \
    && rm -r /usr/lib/python*/ensurepip \
    && rm -rf /var/cache/apk/* /tmp/* \
    && pip3 install --upgrade pip \
    && pip3 --no-cache-dir install \
    boto \
    boto3 \
    hvac \
    ruamel.yaml.clib \
    awscli \
    gitpython \
    ansible-lint \
    pytz \
    && npm install -g @angular/cli \
    && npm install -g @angular-devkit/build-angular \
    && mkdir -p /etc/ansible \
    && echo 'localhost' > /etc/ansible/hosts \
    && cd /usr/local \
    && curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
    && chmod 755 /usr/share/jenkins \
    && chmod 644 /usr/share/jenkins/agent.jar \
    && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar \
    && mkdir -p /home/${user}/.jenkins \
    && mkdir -p ${AGENT_WORKDIR} \
    && chmod +x /usr/local/bin/jenkins-agent /usr/bin/xvfb-chromium \
    && ln -s /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-slave \
    && ln -sf /usr/bin/xvfb-chromium /usr/bin/google-chrome \
    && rm /usr/bin/python \
    && ln -s /usr/bin/python3 /usr/bin/python \
    && rm -vrf /var/cache/apk/* /tmp/*

RUN apk add --update openrc

ENV CHROME_BIN=/usr/bin/google-chrome \
    CHROME_PATH=/usr/lib/chromium/ \
    SONAR_RUNNER_HOME=/usr/lib/sonar-scanner \
    HOME=/var/lib/jenkins \
    AWS_DEFAULT_REGION=us-east-1 \
    AGENT_WORKDIR=${AGENT_WORKDIR}

VOLUME /var/lib/jenkins \
       ${AGENT_WORKDIR}

WORKDIR /var/lib/jenkins

ENTRYPOINT ["jenkins-slave"]