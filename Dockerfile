FROM node:18

ARG GH_CLI_VERSION=2.76.0

RUN apt update && apt install jq wget ripgrep -y

RUN wget https://github.com/cli/cli/releases/download/v${GH_CLI_VERSION}/gh_${GH_CLI_VERSION}_linux_amd64.deb &&\
    apt install ./gh_${GH_CLI_VERSION}_linux_amd64.deb &&\
    rm gh_${GH_CLI_VERSION}_linux_amd64.deb 

RUN npm install -g @openai/codex@0.9.0
