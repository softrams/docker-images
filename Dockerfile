FROM maven:3.8.6-jdk-11

RUN apt-get update && apt-get -y install 

RUN curl -SsL https://downloads.gauge.org/stable | sh

RUN apt-get install -y wget awscli python python3 maven
# Install gauge plugins
RUN gauge install java && \
    gauge install screenshot

ENV PATH=$HOME/.gauge:$PATH