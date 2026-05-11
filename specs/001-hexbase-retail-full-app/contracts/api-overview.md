# API Contracts: Overview

**Branch**: `001-hexbase-retail-full-app` | **Date**: 2026-05-10  
**Base URL**: `https://{tenant}.hexbase.in/api/v1`  
**Auth**: Bearer token (Laravel Sanctum) — `Authorization: Bearer {token}`  
**Tenant**: Resolved from subdomain or `X-Tenant-Code` header  
**Content-Type**: `application/json`

## Conventions

- All responses use a consistent envelope:
  ```json
  { "data": {...}, "meta": {...}, "message": "string" }
  ```
- List responses include `meta.pagination`: `{ "total", "per_page", "current_page", "last_page" }`
- Errors return HTTP 4xx/5xx with `{ "message": "string", "errors": { "field": ["msg"] } }`
- Timestamps in ISO 8601 UTC
- Monetary amounts as strings with 2 decimal places e.g. `"12500.00"` to avoid float precision issues
- All POST/PUT/PATCH require CSRF exemption (API routes) — Sanctum token is sufficient
- Role abbreviations: `admin` = Administrator, `acc` = Accountant, `billing` = Billing Operator, `view` = View-Only

## Contract Files

| File | Modules |
|------|---------|
| [auth.md](auth.md) | Login, logout, password reset, profile |
| [masters.md](masters.md) | Customers, vendors, products |
| [sales.md](sales.md) | Sales invoices, quotations, credit notes, delivery challans |
| [purchases.md](purchases.md) | Purchase invoices, purchase orders, debit notes |
| [receipts-payments.md](receipts-payments.md) | Receipts, payments, expenses |
| [reports.md](reports.md) | GST reports, financial reports, inventory reports |
| [admin.md](admin.md) | Company setup, templates, custom fields, backup, tenant management, activity log |

## Rate Limiting

- Auth endpoints (`/login`, `/password/reset`): 10 requests / minute per IP
- All other endpoints: 120 requests / minute per token
