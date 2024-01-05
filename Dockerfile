FROM maven:3.8.6-openjdk-11

RUN curl "https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem" -o "/usr/local/share/ca-certificates/global-bundle.crt" && \
    update-ca-certificates 
