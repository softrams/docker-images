# Base image: system dependencies + Python/Lambda runtime packages.
# Build and push this image infrequently (only when requirements.txt or
# system dependencies change). The application Dockerfile builds FROM this.
FROM python:3.12-bookworm

ENV FUNCTION_DIR=/var/task \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/var/task:/var/task/src

# Add Lambda Runtime Interface Emulator for local docker invocation parity.
ADD https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie /usr/local/bin/aws-lambda-rie

# Install AWS CLI and LibreOffice from Debian repositories.
RUN apt-get update \
    && apt-get install -y --no-install-recommends awscli libreoffice ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && chmod +x /usr/local/bin/aws-lambda-rie

WORKDIR ${FUNCTION_DIR}

# Install application and Lambda runtime dependencies in site-packages.
COPY requirements.txt ./
RUN python -m pip install --no-cache-dir --upgrade pip \
    && python -m pip install --no-cache-dir -r requirements.txt \
    && python -m pip check \
    && python -c "import awslambdaric"
