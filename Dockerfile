# Building the image
# 	docker build -t gauge-taiko .
# Running the image
# 	docker run  --rm -it -v ${PWD}/reports:/gauge/reports gauge-taiko

# This image uses the official node base image.
FROM golang:1-buster

# The Taiko installation downloads and installs the chromium required to run the tests.
# However, we need the chromium dependencies installed in the environment. These days, most
# Dockerfiles just install chrome to get the dependencies.
RUN apt-get update \
     && apt-get install -y unzip \
     && apt-get install -y zip

