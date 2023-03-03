FROM alpine:3.15.0

MAINTAINER Toan Nguyen <hello@nntoan.com>

# https://docs.newrelic.com/docs/release-notes/agent-release-notes/php-release-notes
ENV NR_PHP_AGENT_VERSION 10.6.0.318

ARG TARGETARCH

WORKDIR /newrelic-php-agent/

RUN apk add --no-cache \
        php7-fpm \
        php7-bcmath \
        php7-bz2 \
        php7-calendar \
        php7-cli \
        php7-common \
        php7-ctype \
        php7-curl \
        php7-dom \
        php7-exif \
        php7-fileinfo \
        php7-ftp \
        php7-gd \
        php7-gettext \
        php7-gmp \
        php7-iconv \
        php7-imagick \
        php7-intl \
        php7-json \
        php7-mbstring \
        php7-mysqli \
        php7-openssl \
        php7-pcntl \
        php7-pdo \
        php7-pdo_mysql \
        php7-pdo_sqlite \
        php7-phar \
        php7-posix \
        php7-session \
        php7-shmop \
        php7-simplexml \
        php7-soap \
        php7-sodium \
        php7-sockets \
        php7-sqlite3 \
        php7-sysvmsg \
        php7-sysvsem \
        php7-sysvshm \
        php7-tokenizer \
        php7-xml \
        php7-xmlreader \
        php7-xmlrpc \
        php7-xmlwriter \
        php7-xsl \
        php7-opcache \
        php7-xdebug \
        php7-redis \
        php7-zip \
        php7-pecl-igbinary \
        php7-pecl-ssh2; \
        ln -snf /usr/bin/php7 /usr/bin/php; \
        ln -s /etc/php7/php.ini /etc/php.ini; \
        ln -s /etc/php7 /etc/php; \
        ln -s /etc/php7/conf.d /etc/php.d; \
        ln -s /etc/php7/php-fpm.d /etc/php-fpm.d; \
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
    apk add --no-cache --virtual .build-deps-nr g++ autoconf automake make libtool nasm libpng-dev libc6-compat && \
    curl -L https://download.newrelic.com/php_agent/release/newrelic-php5-${NR_PHP_AGENT_VERSION}-linux-musl.tar.gz >> /tmp/newrelic-php5-${NR_PHP_AGENT_VERSION}-linux-musl.tar.gz && \
    cd /tmp && \
    tar -xzvf ./newrelic-php5-${NR_PHP_AGENT_VERSION}-linux-musl.tar.gz && \
    NR_INSTALL_USE_CP_NOT_LN=1 NR_INSTALL_SILENT=1 ./newrelic-php5-${NR_PHP_AGENT_VERSION}-linux-musl/newrelic-install install && \
    rm -Rf ./newrelic-php5-* && \
    apk del .build-deps-nr && \
    sed -i "s/.*extension = "newrelic.so".*/;extension = "newrelic.so"/" $(readlink -f /etc/php.d/newrelic.ini); \
    fi;

RUN if [ "$TARGETARCH" = "arm64" ]; then \
    apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community --virtual .build-deps-nr php7-dev git go musl-dev pcre2-dev pcre-dev build-base automake libtool && \
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

