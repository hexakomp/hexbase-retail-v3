-- Docker MySQL init: create tenant demo database
-- The central DB (hexbase_central) is created by MYSQL_DATABASE env var.
CREATE DATABASE IF NOT EXISTS hexbase_tenant_demo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON hexbase_tenant_demo.* TO 'root'@'%';
FLUSH PRIVILEGES;
