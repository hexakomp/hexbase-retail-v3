# Quickstart: Hexbase Retail v3 — Local Development Setup

**Stack**: Laravel 11 (PHP 8.2) + Flutter (Dart 3.x) + MySQL 8.x

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| PHP | 8.2+ | php.net or brew/apt |
| Composer | 2.x | getcomposer.org |
| MySQL | 8.x | mysql.com or Docker |
| Flutter SDK | stable channel | flutter.dev |
| Docker Desktop | optional | docker.com |
| Node.js | 18+ (for frontend tooling) | nodejs.org |

---

## 1. Clone & Bootstrap

```bash
git clone <repo-url> hexbase-retail-v3
cd hexbase-retail-v3
```

---

## 2. Backend Setup

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
```

**Configure `.env`**:

```ini
# Central database (tenant registry)
CENTRAL_DB_HOST=127.0.0.1
CENTRAL_DB_DATABASE=hexbase_central
CENTRAL_DB_USERNAME=root
CENTRAL_DB_PASSWORD=secret

# Default tenant DB connection (resolved dynamically at runtime)
DB_HOST=127.0.0.1
DB_USERNAME=root
DB_PASSWORD=secret

# Queue (database driver for shared hosting)
QUEUE_CONNECTION=database

# Google Drive backup (optional for dev)
GOOGLE_DRIVE_CLIENT_ID=
GOOGLE_DRIVE_CLIENT_SECRET=
GOOGLE_DRIVE_REFRESH_TOKEN=
GOOGLE_DRIVE_FOLDER_ID=

# Admin alert email
ADMIN_ALERT_EMAIL=dev@localhost
```

**Run central database migrations**:

```bash
php artisan migrate --path=database/migrations/central
```

**Provision first tenant**:

```bash
# Via Artisan command (dev/CI shortcut)
php artisan tenant:create --name="Test Shop" --code="test" --subdomain="test"
# This creates hexbase_test database, runs tenant migrations, seeds defaults
```

Or via API (see §6 below).

**Start development server**:

```bash
php artisan serve --host=0.0.0.0 --port=8000
```

---

## 3. Queue Worker (for PDF reports and scheduled backups)

```bash
# For development — run manually
php artisan queue:work --stop-when-empty
```

On production (cPanel shared hosting), add cron job:
```
* * * * * /usr/bin/php /path/to/backend/artisan queue:work --stop-when-empty >> /dev/null 2>&1
```

---

## 4. Frontend Setup

```bash
cd ../frontend
flutter pub get
```

**Configure API base URL**:

Edit `lib/core/config.dart`:

```dart
class AppConfig {
  static const String apiBaseUrl = 'http://127.0.0.1:8000/api/v1';
  static const String tenantCode = 'test';
}
```

> For multi-tenant production, the base URL is derived from subdomain: `https://{tenant}.hexbase.in/api/v1`

**Run on desired platform**:

```bash
flutter run -d chrome           # Web
flutter run -d android          # Android (emulator or device)
flutter run -d windows          # Windows desktop
```

---

## 5. Run Tests

**Backend (PHPUnit)**:

```bash
cd backend
php artisan test
# Or for a specific test suite:
php artisan test --testsuite=Feature
php artisan test --filter=GstCalculatorTest
```

**Frontend (flutter_test)**:

```bash
cd frontend
flutter test
```

---

## 6. First Invoice Walkthrough

1. **Authenticate**: `POST /api/v1/auth/login` with seeded admin credentials (see `database/seeders/TenantSeeder.php`).
2. **Create a product**: `POST /api/v1/products` with HSN, GST rate, selling rate.
3. **Create a customer**: `POST /api/v1/customers` with GSTIN and state code.
4. **Preview tax**: `POST /api/v1/sales-invoices/calculate` — pass customer, place_of_supply, line items.
5. **Create invoice**: `POST /api/v1/sales-invoices` with `"status": "posted"`.
6. **Download PDF**: `GET /api/v1/sales-invoices/{id}/pdf`.

---

## 7. Provision Tenant via API (alternative to Artisan command)

```http
POST /api/super/tenants
Authorization: Bearer <super-admin-token>
Content-Type: application/json

{
  "name": "Test Shop",
  "code": "test",
  "subdomain": "test",
  "plan": "standard"
}
```

The endpoint creates `hexbase_test` database, runs all tenant migrations, and seeds default data (ledger accounts, numbering sequences, default PDF template).

---

## 8. Docker (Optional — Dev/CI)

```bash
# Start MySQL only in Docker (if not installed locally)
docker compose up -d mysql

# Or start full stack
docker compose up -d
```

The `docker-compose.yml` at repo root starts MySQL 8 + phpMyAdmin. Laravel and Flutter run natively.

---

## 9. Environment for Production (Shared Hosting)

1. Upload `backend/` to `public_html/api/` (or subdomain document root)
2. Point web root to `public/`
3. Set `.env` values in cPanel environment manager
4. Run `composer install --no-dev --optimize-autoloader`
5. Run `php artisan migrate` (runs tenant + central migrations per configured DB)
6. Add cron job for queue worker (see §3)
7. Set up Google Drive credentials for scheduled backup
