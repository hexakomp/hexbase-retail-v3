FROM php:8.2-fpm

# System dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy application code
COPY backend/ .

# Install PHP dependencies (including dev for artisan commands)
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# Set correct permissions for storage and cache
RUN mkdir -p /var/www/html/storage/logs \
    /var/www/html/storage/framework/cache \
    /var/www/html/storage/framework/sessions \
    /var/www/html/storage/framework/views \
    /var/www/html/bootstrap/cache \
    && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Copy entrypoint scripts
COPY docker/backend/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY docker/backend/docker-migrate.sh /usr/local/bin/docker-migrate.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-migrate.sh

EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
