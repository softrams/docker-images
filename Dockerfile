FROM node:20.11.1

ARG GH_CLI_VERSION=2.76.0

# Install Google Chrome
RUN apt-get update && \
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt install --assume-yes ./google-chrome-stable_current_amd64.deb zip jq wget ripgrep

RUN wget https://github.com/cli/cli/releases/download/v${GH_CLI_VERSION}/gh_${GH_CLI_VERSION}_linux_amd64.deb &&\
    apt install ./gh_${GH_CLI_VERSION}_linux_amd64.deb &&\
    rm gh_${GH_CLI_VERSION}_linux_amd64.deb

RUN npm install -g @anthropic-ai/claude-code@1.0.69

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" &&\
    unzip awscliv2.zip && \
    ./aws/install &&\
    rm -rf aws &&\
    rm awscliv2.zip
