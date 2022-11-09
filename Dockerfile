FROM newrelic/nri-ecs:latest

ENV APACHE_STATUS http://127.0.0.1/server-status?auto
COPY etc /etc
