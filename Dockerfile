FROM debian:latest AS build_stage
LABEL org.opencontainers.image.description "Softrams DevOps Tools (including gitLeaks,\
	sonar-cli, grype, and semgrep"
RUN apt-get update && apt-get install git curl python3 python3-pip -y \
	&& cd /opt \
	&& curl -v https://dl.softrams.cloud/devops-tools.tar.gz -o devops-tools.tar.gz \
	&& tar -zxvf devops-tools.tar.gz \
	&& rm -f devops-tools.tar.gz \
	&& ln -sf /opt/tools/gitleaks_8.20.1_linux_x64 /usr/bin/gitleaks \
	&& cd /opt/tools && tar -zxvf sonar-scanner-6.2.1.4610-linux-x64.tar.gz \
	&& ln -sf /opt/tools/sonar-scanner-6.2.1.4610-linux-x64/bin/sonar-scanner /usr/bin/\
	&& tar -zxvf cosign-linux-amd64.tar.gz \
	&& mv /opt/tools/cosign-linux-amd64 /usr/bin/cosign \
	&& chmod +x /usr/bin/cosign \
	&& cat /opt/tools/grype.sh | sh -s -- -b /usr/bin \
	&& pip3 install semgrep --break-system-packages
