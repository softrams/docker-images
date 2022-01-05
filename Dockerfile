FROM jenkins/jnlp-slave:alpine

#
ENV JENKINS_WEB_SOCKET true

# Simplify permissions in this containerized instance
USER root

# Install Docker
RUN apk add -U --no-cache docker

# Also install awscli
RUN apk add -U curl python python-dev py-pip build-base
RUN pip install awscli

# Setup jenkins-agent
COPY ./dockerd-entrypoint.sh /usr/local/bin/dockerd-entrypoint.sh
RUN mv /usr/local/bin/jenkins-slave /usr/local/bin/jenkins-agent
RUN chmod +x /usr/local/bin/jenkins-agent /usr/local/bin/dockerd-entrypoint.sh

# Entrypoint
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
