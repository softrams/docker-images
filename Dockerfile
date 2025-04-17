FROM alpine:latest

RUN apk add --update dotnet-sdk
RUN apk add --update dotnet-runtime
