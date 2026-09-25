FROM php:8.4-fpm-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git unzip nginx default-mysql-client postgresql-client libpq-dev libicu-dev \
    && docker-php-ext-install pdo_mysql pdo_pgsql intl bcmath \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY composer.json composer.lock ./
RUN composer install --no-interaction --prefer-dist --no-scripts --no-dev

COPY . .
RUN composer dump-autoload --optimize \
    && chown -R www-data:www-data storage bootstrap/cache

COPY docker/nginx/render.conf.template /opt/nginx/render.conf.template
COPY docker/entrypoint.sh /entrypoint.sh
COPY docker/start-http.sh /start-http.sh
RUN chmod +x /entrypoint.sh /start-http.sh \
    && rm -f /etc/nginx/sites-enabled/default

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/start-http.sh"]
