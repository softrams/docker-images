FROM node:22


RUN wget https://github.com/cli/cli/releases/download/v2.74.2/gh_2.74.2_linux_amd64.deb &&\
    apt install ./gh_2.74.2_linux_amd64.deb &&\
    rm gh_2.74.2_linux_amd64.deb 

RUN npm install -g @openai/codex
