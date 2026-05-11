# Deployment Guide — HexBase Retail v3 (Backend)

## Prerequisites

- PHP 8.2+
- Composer 2.x
- MySQL 8.x
- A queue worker (Supervisor recommended)
- A cron job for Laravel scheduler

---

## 1. Upload Files

Upload the contents of the `backend/` directory to your server's web root (e.g., `/var/www/hexbase/`).

> **Important**: The `public/` folder should be the document root for your web server / virtual host.

---

## 2. Install PHP Dependencies

```bash
cd /var/www/hexbase
composer install --no-dev --optimize-autoloader
```

---

## 3. Configure Environment

Copy the example environment file and fill in your values:

```bash
cp .env.example .env
php artisan key:generate
```

Edit `.env`:

```ini
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-domain.com

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=hexbase_central
DB_USERNAME=your_db_user
DB_PASSWORD=your_db_password

QUEUE_CONNECTION=database   # or redis
CACHE_DRIVER=file           # or redis

MAIL_MAILER=smtp
MAIL_HOST=smtp.your-provider.com
MAIL_PORT=587
MAIL_USERNAME=your@email.com
MAIL_PASSWORD=your_password
MAIL_FROM_ADDRESS=noreply@your-domain.com
MAIL_FROM_NAME="HexBase Retail"
```

---

## 4. Run Migrations

### Central database

```bash
php artisan migrate --database=mysql
```

### Tenant databases

For each tenant (run once per tenant or via seed):

```bash
php artisan tenants:migrate
```

---

## 5. Storage Link

```bash
php artisan storage:link
```

This creates a `public/storage` symlink to `storage/app/public/`.

---

## 6. Cache Configuration

```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

---

## 7. Queue Worker (Supervisor)

Create `/etc/supervisor/conf.d/hexbase-worker.conf`:

```ini
[program:hexbase-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/hexbase/artisan queue:work database --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/www/hexbase/storage/logs/worker.log
```

```bash
supervisorctl reread
supervisorctl update
supervisorctl start hexbase-worker:*
```

---

## 8. Laravel Scheduler (Cron)

Add to crontab (`crontab -e` as `www-data` or root):

```cron
* * * * * cd /var/www/hexbase && php artisan schedule:run >> /dev/null 2>&1
```

---

## 9. Web Server Configuration

### Nginx

```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /var/www/hexbase/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

---

## 10. Post-Deploy Checklist

- [ ] `APP_DEBUG=false` in production
- [ ] HTTPS configured (Let's Encrypt / SSL cert)
- [ ] Queue worker running via Supervisor
- [ ] Scheduler cron active
- [ ] `storage/` and `bootstrap/cache/` are writable by web server
- [ ] Backups configured (S3 or local disk)
- [ ] Log rotation configured
