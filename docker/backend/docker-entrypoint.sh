#!/bin/sh
set -e

cd /var/www/html

echo "==> Generating .env from environment..."
cat > .env <<EOF
APP_NAME="${APP_NAME:-Hexbase Retail}"
APP_ENV=${APP_ENV:-local}
APP_KEY=${APP_KEY:-}
APP_DEBUG=${APP_DEBUG:-true}
APP_URL=${APP_URL:-http://localhost:8080}

LOG_CHANNEL=${LOG_CHANNEL:-stderr}

DB_CONNECTION=${DB_CONNECTION:-central}
DB_HOST=${DB_HOST:-mysql}
DB_PORT=${DB_PORT:-3306}
DB_USERNAME=${DB_USERNAME:-root}
DB_PASSWORD=${DB_PASSWORD:-secret}

CENTRAL_DB_DATABASE=${CENTRAL_DB_DATABASE:-hexbase_central}

TENANT_DB_HOST=${TENANT_DB_HOST:-${DB_HOST:-mysql}}
TENANT_DB_PORT=${TENANT_DB_PORT:-3306}
TENANT_DB_USERNAME=${TENANT_DB_USERNAME:-root}
TENANT_DB_PASSWORD=${TENANT_DB_PASSWORD:-secret}
TENANT_DB_PREFIX=${TENANT_DB_PREFIX:-hexbase_}

CACHE_STORE=${CACHE_STORE:-database}
SESSION_DRIVER=${SESSION_DRIVER:-database}
QUEUE_CONNECTION=${QUEUE_CONNECTION:-database}
FILESYSTEM_DISK=local
EOF

# Generate APP_KEY if not set
if [ -z "$APP_KEY" ]; then
  echo "==> Generating APP_KEY..."
  php artisan key:generate --force
fi

echo "==> Clearing config cache..."
php artisan config:clear

echo "==> Starting php-fpm..."
exec php-fpm
