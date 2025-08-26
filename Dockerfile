FROM php:7.4-apache

# Installa librerie di sistema necessarie
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    libicu-dev \
    libonig-dev \
    libxml2-dev \
    libxslt1-dev \
    libpq-dev \
    libsqlite3-dev \
    pkg-config \
    zip \
    unzip \
    git \
    curl \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Configura GD con supporto per freetype e jpeg
RUN docker-php-ext-configure gd --with-freetype --with-jpeg

# Estensioni core PHP
RUN docker-php-ext-install \
    mysqli \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    pdo_sqlite \
    gd \
    intl \
    mbstring \
    zip \
    opcache \
    calendar \
    exif \
    tokenizer

# Estensioni XML/DOM/XSL
RUN CFLAGS="-I/usr/src/php" docker-php-ext-install -j$(nproc) \
    dom \
    xml \
    simplexml \
    xmlreader \
    xmlwriter \
    xsl \
    soap

# Abilita mod_rewrite e mod_ssl
RUN a2enmod rewrite ssl

# Abilita il VirtualHost SSL di default
RUN a2ensite default-ssl

# PECL extensions
RUN apt-get update && apt-get install -y libssl-dev && rm -rf /var/lib/apt/lists/*
RUN pecl install redis && docker-php-ext-enable redis
RUN pecl install mongodb-1.10.0 && docker-php-ext-enable mongodb