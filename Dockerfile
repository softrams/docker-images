FROM node:22

RUN apt update &&\
    apt install zip -y

RUN npm install -g typescript

