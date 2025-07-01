FROM node:22

RUN apt update &&\
    apt upgrade -y 

RUN npm install -g @openai/codex
