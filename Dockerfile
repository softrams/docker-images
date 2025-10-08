FROM node:22-alpine
    
RUN apk update
RUN apk add libgcrypt antiword