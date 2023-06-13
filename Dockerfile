FROM debian:11-slim 

RUN apt update && apt upgrade -y && apt install podman -y
