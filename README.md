# Hexbase Retail V3

Short description of the project.

## Prerequisites

- [Docker](https://www.docker.com/) and [Docker Compose](https://docs.docker.com/compose/)
- [PHP 8.2+](https://www.php.net/)
- [Composer](https://getcomposer.org/)
- [Flutter 3.x](https://docs.flutter.dev/get-started/install)

---

## Step-by-Step Setup

### 1. Start Infrastructure (MySQL)

Run only the MySQL container using Docker Compose:

```bash
docker compose up -d mysql
```

### 2. Backend Setup (Laravel)

Navigate to the backend directory and set up the dependencies and environment:

```bash
cd backend
composer install
# Ensure .env is configured correctly (already set to use 127.0.0.1 for DB_HOST)
php artisan key:generate
```

### 3. Run Migrations

Run the central database migrations:

```bash
php artisan migrate --path=database/migrations/central
```

*Note: Tenant migrations are handled automatically during tenant provisioning.*

### 4. Start the Backend Server

Start the Laravel development server:

```bash
php artisan serve --port=8000
```

### 5. Frontend Setup (Flutter)

In a new terminal, navigate to the frontend directory:

```bash
cd frontend
flutter pub get
```

### 6. Start the Frontend App

Run the Flutter app (e.g., for Chrome/Web):

```bash
flutter run -d chrome
```

---

## Environment Configuration

The backend `.env` is configured to connect to MySQL at `127.0.0.1:3306`. If you change the MySQL port in `docker-compose.yml`, update `DB_PORT` and `TENANT_DB_PORT` accordingly in `backend/.env`.
