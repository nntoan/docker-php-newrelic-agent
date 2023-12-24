FROM alpine:3.16.2

MAINTAINER Toan Nguyen <hello@nntoan.com>

# https://docs.newrelic.com/docs/release-notes/agent-release-notes/php-release-notes
ENV NR_PHP_AGENT_VERSION 10.15.0.4

ARG TARGETARCH

WORKDIR /newrelic-php-agent/

RUN apk add --no-cache \
        php81-fpm \
        php81-bcmath \
        php81-bz2 \
        php81-calendar \
        php81-common \
        php81-ctype \
        php81-curl \
        php81-dom \
        php81-exif \
        php81-fileinfo \
        php81-ftp \
        php81-gd \
        php81-gettext \
        php81-gmp \
        php81-iconv \
        php81-pecl-imagick \
        php81-intl \
        php81-mbstring \
        php81-mysqli \
        php81-openssl \
        php81-pcntl \
        php81-pdo \
        php81-pdo_mysql \
        php81-pdo_sqlite \
        php81-phar \
        php81-posix \
        php81-session \
        php81-shmop \
        php81-simplexml \
        php81-soap \
        php81-sodium \
        php81-sockets \
        php81-sqlite3 \
        php81-sysvmsg \
        php81-sysvsem \
        php81-sysvshm \
        php81-tokenizer \
        php81-xml \
        php81-xmlreader \
        php81-xmlwriter \
        php81-xsl \
        php81-opcache \
        php81-pecl-xdebug \
        php81-pecl-redis \
        php81-zip \
        php81-pecl-igbinary \
        php81-pecl-ssh2 \
        php81-phpdbg; \
        ln -s /etc/php81/php.ini /etc/php.ini; \
        ln -s /etc/php81 /etc/php; \
        ln -s /etc/php81/conf.d /etc/php.d; \
        ln -s /etc/php81/php-fpm.d /etc/php-fpm.d; \
        ln -s /usr/bin/php81 /usr/local/bin/php; \
        sed -i \
                -e "s/;\?date.timezone =.*/date.timezone = UTC/" \
                -e "s/;\?opcache.blacklist_filename=.*/opcache.blacklist_filename=\/etc\/php.d\/opcache\*.blacklist/" \
                $(readlink -f /etc/php.ini);

RUN mkdir -p /newrelic-php-agent/dist

RUN apk add --no-cache \
        gettext \
        unzip \
        gzip \
        tar \
        which \
        patch \
        curl \
        libxml2;

# Install NewRelic
RUN if [ "$TARGETARCH" = "amd64" ]; then \
    apk add --no-cache --virtual .build-deps-nr bash g++ autoconf automake make libtool nasm libpng-dev libc6-compat && \
    curl -L https://download.newrelic.com/php_agent/archive/${NR_PHP_AGENT_VERSION}/newrelic-php5-${NR_PHP_AGENT_VERSION}-linux-musl.tar.gz >> /tmp/newrelic-php5-${NR_PHP_AGENT_VERSION}-linux-musl.tar.gz && \
    cd /tmp && \
    tar -xzvf ./newrelic-php5-${NR_PHP_AGENT_VERSION}-linux-musl.tar.gz && \
    NR_INSTALL_USE_CP_NOT_LN=1 NR_INSTALL_SILENT=1 ./newrelic-php5-${NR_PHP_AGENT_VERSION}-linux-musl/newrelic-install install && \
    rm -Rf ./newrelic-php5-* && \
    apk del .build-deps-nr && \
    sed -i "s/.*extension = "newrelic.so".*/;extension = "newrelic.so"/" $(readlink -f /etc/php.d/newrelic.ini); \
    fi;

RUN if [ "$TARGETARCH" = "arm64" ]; then \
    apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community --virtual bash .build-deps-nr php81-dev git go musl-dev pcre2-dev pcre-dev build-base automake libtool && \
    curl -L -o /tmp/v${NR_PHP_AGENT_VERSION}.zip https://github.com/newrelic/newrelic-php-agent/archive/refs/tags/v${NR_PHP_AGENT_VERSION}.zip && \
    cd /tmp && \
    unzip v${NR_PHP_AGENT_VERSION}.zip && \
    cd newrelic-php-agent-${NR_PHP_AGENT_VERSION} && \
    git init && \
    make all && make agent-install && \
    mkdir -p 0777 /var/log/newrelic && \
    cp bin/daemon /usr/bin/newrelic-daemon && \
    cp /tmp/newrelic-php-agent-${NR_PHP_AGENT_VERSION}/agent/scripts/newrelic.ini.template $(readlink -f /etc/php.d/newrelic.ini) && \
    rm -rf /tmp/v${NR_PHP_AGENT_VERSION}.zip /tmp/newrelic-php-agent-${NR_PHP_AGENT_VERSION} && \
    apk del .build-deps-nr && \
    sed -i "s/.*extension = "newrelic.so".*/;extension = "newrelic.so"/" $(readlink -f /etc/php.d/newrelic.ini); \
    fi;

# Post-install
RUN cp $(readlink -f /etc/php.d/newrelic.ini) /newrelic-php-agent/dist/newrelic.ini; \
    cp $(php -r "echo ini_get ('extension_dir');")/newrelic.so /newrelic-php-agent/dist/newrelic.so; \
    cp /usr/bin/newrelic-daemon /newrelic-php-agent/dist/newrelic-daemon;

