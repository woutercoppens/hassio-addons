ARG BUILD_FROM=ghcr.io/hassio-addons/debian-base/amd64:11.0.0
# hadolint ignore=DL3006
FROM $BUILD_FROM

ENV LANG C.UTF-8

# Environment variables
ENV APP_ID="spotweb"
ENV APP_NAME="Spotweb"
ENV APP_DIR="/app"
ENV SPOTWEB_RELEASE="1.5.1"

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Setup base system
ARG BUILD_ARCH=amd64
# Install app dependencies
RUN apk -U update && \
    apk -U upgrade && \
    apk -U add --no-cache \
        tar \
        wget \
        nginx \
        php8 \
        php8-fpm \
        php8-curl \
        php8-dom \
        php8-gettext \
        php8-xml \
        php8-simplexml \
        php8-zip \
        php8-zlib \
        php8-gd \
        php8-openssl \
        php8-mysqli \
        php8-pdo \
        php8-pdo_mysql \
        php8-pgsql \
        php8-pdo_pgsql \
        php8-sqlite3 \
        php8-pdo_sqlite \
        php8-json \
        php8-mbstring \
        php8-ctype \
        php8-opcache \
        php8-session \
        mariadb-client \
    && \
    && mkdir -p /app \
    git clone --depth=1 https://github.com/spotweb/spotweb.git /app && \    # Install latest Spotweb release
    # spotweb needs a timezone set in the php.ini
    # TODO: Can we dynamically set the correct timezone here ?
    && sed -i "s/;date.timezone =/date.timezone = \"Europe\/Amsterdam\"/g" /etc/php7/php.ini \
    \
    && rm -fr \
        /tmp/* \
        /var/{cache,log}/* \
        /var/lib/apt/lists/* \
        /etc/nginx \
    \
    && mkdir -p /var/log/nginx \
    && touch /var/log/nginx/error.log

# Copy rootfs
COPY rootfs /

# Build arguments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION


# Labels
LABEL \
    io.hass.name="${APP_NAME}" \
    io.hass.description="${APP_NAME} Add-on for Home Assistant" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Wouter" \
    org.label-schema.description="${APP_NAME} Add-on for Home Assistant" \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.name="${APP_NAME}" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.url="https://github.com/woutercoppens/hassio-addons/${APP_ID}" \
    org.label-schema.usage="https://github.com/woutercoppens/hassio-addons/tree/master/${APP_ID}/README.md" \
    org.label-schema.vcs-ref=${BUILD_REF} \
    org.label-schema.vcs-url="https://github.com/woutercoppens/hassio-addons/${APP_ID}" \
    org.label-schema.vendor="Wouter's Community Add-ons for Home Assistant"