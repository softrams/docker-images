FROM jenkins/jnlp-slave:alpine

#
ENV JENKINS_WEB_SOCKET true

# Simplify permissions in this containerized instance
USER root

# Install Docker
RUN apk add -U --no-cache docker

# Also install awscli
RUN apk add -U curl python3 python3-dev py3-pip build-base
RUN pip3 install awscli

# Setup jenkins-agent
COPY ./dockerd-entrypoint.sh /usr/local/bin/dockerd-entrypoint.sh
RUN mv /usr/local/bin/jenkins-slave /usr/local/bin/jenkins-agent

# Entrypoint
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
