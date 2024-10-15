FROM --platform=linux/amd64 debian:latest AS build_stage
LABEL org.opencontainers.image.description "kaniko-executor base image; \
	https://github.com/GoogleContainerTools/kaniko"
ENV PATH="$PATH:/kaniko"
ENV HOME="/root"
ENV USER="root"
ENV SSL_CERT_DIR="/kaniko/ssl/certs"
ENV DOCKER_CONFIG="/kaniko/.docker/"
ENV DOCKER_CREDENTIAL_GCR_CONFIG="/kaniko/.config/gcloud/docker_credential_gcr_config.json"
WORKDIR /workspace
COPY --from=gcr.io/kaniko-project/executor:latest /kaniko /kaniko
USER root

ENTRYPOINT ["tail", "-f", "/dev/null"]