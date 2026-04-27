# ========== STAGE 1 : Builder ==========
FROM composer:2 AS builder
WORKDIR /app
COPY composer.json composer.lock* ./
RUN composer install \
    --no-dev \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --prefer-dist \
    --optimize-autoloader

# Nettoyage agressif des dossiers inutiles dans vendor
RUN find vendor -type d -name "tests" -exec rm -rf {} + \
    && find vendor -type d -name "docs" -exec rm -rf {} + \
    && find vendor -type f -name "README.md" -exec rm -rf {} +

# ========== STAGE 2 : Production ==========
FROM alpine:3.20 AS production
WORKDIR /var/www/html

# Installation de PHP et des extensions via APK (beaucoup plus léger)
RUN apk add --no-cache \
    php83-fpm \
    php83-pdo_pgsql \
    php83-mbstring \
    php83-xml \
    php83-openssl \
    php83-curl \
    php83-tokenizer \
    php83-session \
    php83-redis

# Créer un lien symbolique pour utiliser 'php' au lieu de 'php83'
RUN ln -s /usr/bin/php83 /usr/bin/php

# Configurer PHP-FPM pour écouter sur le port 9000
RUN sed -i 's/listen = 127.0.0.1:9000/listen = 9000/g' /etc/php83/php-fpm.d/www.conf \
    && sed -i 's/user = .*/user = www-data/g' /etc/php83/php-fpm.d/www.conf \
    && sed -i 's/group = .*/group = www-data/g' /etc/php83/php-fpm.d/www.conf

# S'assurer que l'utilisateur www-data existe
RUN if ! getent group www-data; then addgroup -g 82 -S www-data; fi \
    && if ! getent passwd www-data; then adduser -u 82 -D -S -G www-data www-data; fi

# Copier le code source sélectivement
COPY app/ ./app/
COPY bootstrap/ ./bootstrap/
COPY config/ ./config/
COPY database/ ./database/
COPY public/ ./public/
COPY routes/ ./routes/
COPY artisan ./

# Copier les vendor nettoyés
COPY --from=builder /app/vendor/ ./vendor/

# Permissions
RUN mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache \
    && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

USER www-data

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD pgrep php-fpm83 || exit 1

EXPOSE 9000
CMD ["php-fpm83", "-F"]
