FROM php:7.2.0-fpm-alpine3.7

RUN \
 apk add --update --no-cache \
	php7-sqlite3 \
        zlib-dev \
 && docker-php-ext-install zip \
 && mkdir /var/database \
 && chown -R www-data:www-data /var/database
