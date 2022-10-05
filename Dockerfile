FROM alpine:3.15

ARG SONAR_SCANNER_HOME=/opt/sonar-scanner
ARG SONAR_SCANNER_VERSION=4.6.2.2472
ARG UID=1000
ARG GID=1000
ARG MAVEN_VERSION=3.6.3
ARG USER_HOME_DIR="/root"
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries
ENV JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk \
    HOME=/tmp \
    XDG_CONFIG_HOME=/tmp \
    SONAR_SCANNER_HOME=${SONAR_SCANNER_HOME} \
    SONAR_USER_HOME=${SONAR_SCANNER_HOME}/.sonar \
    PATH=${SONAR_SCANNER_HOME}/bin:${PATH} \
    NODE_PATH=/usr/lib/node_modules \
    SRC_PATH=/usr/src \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    MAVEN_HOME=/usr/share/maven \
    MAVEN_CONFIG="$USER_HOME_DIR/.m2"

WORKDIR /opt

RUN set -eux; \
    addgroup -S -g ${GID} scanner-cli; \
    adduser -S -D -u ${UID} -G scanner-cli scanner-cli; \
    apk add --no-cache --virtual build-dependencies wget unzip gnupg; \
    apk add --no-cache git python3 py-pip bash shellcheck 'nodejs>12' openjdk8 openjdk8-jre curl musl-locales musl-locales-lang; \
    wget -U "scannercli" -q -O /opt/sonar-scanner-cli.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip; \
    wget -U "scannercli" -q -O /opt/sonar-scanner-cli.zip.asc https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip.asc; \
    for server in $(shuf -e hkps://keys.openpgp.org \
                            hkps://keyserver.ubuntu.com) ; do \
        gpg --batch --keyserver "${server}" --recv-keys 679F1EE92B19609DE816FDE81DB198F93525EC1A && break || : ; \
    done; \
    gpg --verify /opt/sonar-scanner-cli.zip.asc /opt/sonar-scanner-cli.zip; \
    unzip sonar-scanner-cli.zip; \
    rm sonar-scanner-cli.zip sonar-scanner-cli.zip.asc; \
    mv sonar-scanner-${SONAR_SCANNER_VERSION} ${SONAR_SCANNER_HOME}; \
    pip install --no-cache-dir --upgrade pip; \
    pip install --no-cache-dir pylint; \
    apk del --purge build-dependencies; \
    mkdir -p "${SRC_PATH}" "${SONAR_USER_HOME}" "${SONAR_USER_HOME}/cache"; \
    chown -R scanner-cli:scanner-cli "${SONAR_SCANNER_HOME}" "${SRC_PATH}"; \
    chmod -R 777 "${SRC_PATH}" "${SONAR_USER_HOME}";

COPY --chown=scanner-cli:scanner-cli bin /usr/bin/
COPY settings-docker.xml /usr/share/maven/ref/

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

VOLUME [ "/tmp/cacerts" ]

WORKDIR ${SRC_PATH}

ENTRYPOINT ["/usr/bin/entrypoint.sh"]

CMD ["sonar-scanner"]
