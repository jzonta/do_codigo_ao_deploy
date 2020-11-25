FROM php:7.4-fpm

ENV LD_LIBRARY_PATH="/opt/oracle/instantclient_12_1"
ENV OCI_HOME="/opt/oracle/instantclient_12_1"
ENV OCI_LIB_DIR="/opt/oracle/instantclient_12_1"
ENV OCI_INCLUDE_DIR="/opt/oracle/instantclient_12_1/sdk/include"
ENV OCI_VERSION=12

WORKDIR /var/www

# Set timezone
RUN ln -snf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && echo America/Sao_Paulo > /etc/timezone \
&& printf '[PHP]\ndate.timezone = "%s"\n', America/Sao_Paulo > /usr/local/etc/php/conf.d/tzone.ini

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libxml2-dev \
    && docker-php-ext-configure gd \
    && docker-php-ext-install soap \
    && docker-php-ext-install -j$(nproc) gd

ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/install-php-extensions /usr/local/bin/
RUN chmod uga+x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions imagick

RUN set -xe; \
    apt-get update -yqq && \
    pecl channel-update pecl.php.net && \
    apt-get install -yqq \
      wget \
      git \
      libzip-dev \
      zip \
      unzip \
      && docker-php-ext-configure zip && \
      # Install the zip extension
      docker-php-ext-install zip && \
      php -m | grep -q 'zip'

# Install Oracle Instantclient
RUN mkdir /opt/oracle \
    && cd /opt/oracle \
    && wget https://github.com/pwnlabs/oracle-instantclient/raw/master/instantclient-basic-linux.x64-12.1.0.2.0.zip \
    && wget https://github.com/pwnlabs/oracle-instantclient/raw/master/instantclient-sdk-linux.x64-12.1.0.2.0.zip \
    && unzip /opt/oracle/instantclient-basic-linux.x64-12.1.0.2.0.zip -d /opt/oracle \
    && unzip /opt/oracle/instantclient-sdk-linux.x64-12.1.0.2.0.zip -d /opt/oracle \
    && ln -s /opt/oracle/instantclient_12_1/libclntsh.so.12.1 /opt/oracle/instantclient_12_1/libclntsh.so \
    && ln -s /opt/oracle/instantclient_12_1/libclntshcore.so.12.1 /opt/oracle/instantclient_12_1/libclntshcore.so \
    && ln -s /opt/oracle/instantclient_12_1/libocci.so.12.1 /opt/oracle/instantclient_12_1/libocci.so \
    && rm -rf /opt/oracle/*.zip

RUN apt-get update && apt-get install -y libldap2-dev && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
    docker-php-ext-install ldap

# Install bash
RUN apt install bash-completion

# Install PHP extensions deps
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        libaio-dev \
        freetds-dev \
        libicu-dev \
        g++ \
        libxrender1 \
    && echo 'instantclient,/opt/oracle/instantclient_12_1/' | pecl install oci8 \
    && docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/opt/oracle/instantclient_12_1,12.1 \
    && docker-php-ext-configure pdo_dblib --with-libdir=/lib/x86_64-linux-gnu

RUN docker-php-ext-install pdo_oci intl opcache
RUN docker-php-ext-enable oci8 intl opcache

# Install Nodejs
RUN curl -sL https://deb.nodesource.com/setup_12.x | apt-get install -y nodejs npm
RUN curl https://www.npmjs.com/install.sh | sh

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN chown -R www-data:www-data /var/www
