FROM node:22


RUN apt update && apt install jq wget ripgrep -y

RUN wget https://github.com/cli/cli/releases/download/v2.74.2/gh_2.74.2_linux_amd64.deb &&\
    apt install ./gh_2.74.2_linux_amd64.deb &&\
    rm gh_2.74.2_linux_amd64.deb 

RUN npm install -g @openai/codex@0.1.2504172351
