# ========== STAGE 1 : Builder ==========
FROM composer:2.7 AS builder
WORKDIR /app
COPY composer.json composer.lock* ./
RUN composer install \
    --no-dev \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --prefer-dist \
    --optimize-autoloader \
    && find vendor \( \
        -type d -name "tests" \
        -o -type d -name "Tests" \
        -o -type d -name "docs" \
        -o -type d -name ".git" \
        -o -type f -name "*.md" \
        -o -type f -name "*.txt" \
        -o -type f -name "*.rst" \
        -o -type f -name "composer.json" \
        -o -type f -name "composer.lock" \
        -o -type f -name "CHANGELOG*" \
        -o -type f -name "LICENSE*" \
        -o -type f -name "CONTRIBUTING*" \
        -o -type f -name "phpunit.xml*" \
        -o -type f -name "*.sh" \
    \) -exec rm -rf {} + 2>/dev/null; true

# ========== STAGE 2 : Production ==========
FROM alpine:3.20.1 AS production
WORKDIR /var/www/html

RUN apk add --no-cache \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main \
    php84 \
    php84-fpm \
    php84-pdo_pgsql \
    php84-mbstring \
    php84-xml \
    php84-dom \
    php84-openssl \
    php84-curl \
    php84-tokenizer \
    php84-session \
    php84-redis \
    libpq \
    && ln -sf /usr/bin/php84 /usr/bin/php \
    && ln -sf /usr/sbin/php-fpm84 /usr/sbin/php-fpm \
    && sed -i 's/listen = 127.0.0.1:9000/listen = 9000/g' /etc/php84/php-fpm.d/www.conf \
    && [ -f /etc/php84/php-fpm.conf ] && sed -i 's/;error_log = log\/php84\/error.log/error_log = \/dev\/stderr/g' /etc/php84/php-fpm.conf || true \
    && addgroup -g 82 -S www-data 2>/dev/null; \
       adduser  -u 82 -D -S -G www-data www-data 2>/dev/null; true \
    && rm -rf /var/cache/apk/*

# Copier le code proprement (un dossier par ligne pour garder la structure)
COPY --chown=www-data:www-data app/ ./app/
COPY --chown=www-data:www-data bootstrap/ ./bootstrap/
COPY --chown=www-data:www-data config/ ./config/
COPY --chown=www-data:www-data database/ ./database/
COPY --chown=www-data:www-data public/ ./public/
COPY --chown=www-data:www-data routes/ ./routes/
COPY --chown=www-data:www-data artisan .env.example ./

COPY --chown=www-data:www-data --from=builder /app/vendor/ ./vendor/

# Initialisation
RUN mkdir -p \
        storage/framework/cache/data \
        storage/framework/sessions \
        storage/framework/views \
        storage/logs \
        bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && cp .env.example .env \
    && php artisan key:generate \
    && rm -rf database/factories database/seeders .env.example

USER www-data
EXPOSE 9000
CMD ["php-fpm", "-F"]