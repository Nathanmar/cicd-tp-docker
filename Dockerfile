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
    --optimize-autoloader

# Nettoyage agressif
RUN find vendor -type d -name "tests" -exec rm -rf {} + \
    && find vendor -type d -name "docs" -exec rm -rf {} +

# ========== STAGE 2 : Production ==========
FROM alpine:3.20.1 AS production
WORKDIR /var/www/html

# Utiliser les dépôts edge pour avoir PHP 8.4 et les libs compatibles
RUN apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main \
    php84 \
    php84-fpm \
    php84-pdo_pgsql \
    php84-pdo \
    php84-mbstring \
    php84-xml \
    php84-xmlwriter \
    php84-dom \
    php84-openssl \
    php84-curl \
    php84-tokenizer \
    php84-session \
    php84-redis \
    libpq

# Liens symboliques pour PHP 8.4
RUN ln -sf /usr/bin/php84 /usr/bin/php \
    && ln -sf /usr/sbin/php-fpm84 /usr/sbin/php-fpm

# Configurer PHP-FPM 8.4
RUN sed -i 's/listen = 127.0.0.1:9000/listen = 9000/g' /etc/php84/php-fpm.d/www.conf \
    && sed -i 's/user = .*/user = www-data/g' /etc/php84/php-fpm.d/www.conf \
    && sed -i 's/group = .*/group = www-data/g' /etc/php84/php-fpm.d/www.conf \
    && sed -i 's/;error_log = .*/error_log = \/dev\/stderr/g' /etc/php84/php-fpm.conf

# S'assurer que l'utilisateur www-data existe
RUN if ! getent group www-data; then addgroup -g 82 -S www-data; fi \
    && if ! getent passwd www-data; then adduser -u 82 -D -S -G www-data www-data; fi

# Copier le code source
COPY app/ ./app/
COPY bootstrap/ ./bootstrap/
COPY config/ ./config/
COPY database/ ./database/
COPY public/ ./public/
COPY routes/ ./routes/
COPY artisan ./

# Copier les vendor
COPY --from=builder /app/vendor/ ./vendor/

# Permissions
RUN mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache \
    && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

USER www-data

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD pgrep php-fpm84 || exit 1

EXPOSE 9000
CMD ["php-fpm84", "-F"]
