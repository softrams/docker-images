FROM maven:3.8.6-openjdk-18

RUN apt update && \
  apt install -y git && \
  rm -rf /var/lib/apt/lists/*
