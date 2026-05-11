# Implementation Plan: Hexbase-Retail — Small Shop GST Accounting System

**Branch**: `001-hexbase-retail-full-app` | **Date**: 2026-05-10 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-hexbase-retail-full-app/spec.md`

## Summary

Hexbase-Retail is a full-stack small-shop GST accounting system for Indian businesses (2–10 users). The backend is a Laravel 11 REST API deployed on shared hosting; the frontend is a Flutter application targeting Android, iOS, Windows, and web. The system handles sales invoicing, purchase entry, receipts, payments, quotations, purchase orders, delivery challans, expenses, inventory, GST reports (GSTR-1, GSTR-3B), financial reports (trial balance, P&L, balance sheet), double-entry accounting, multi-tenant database isolation, configurable custom fields/columns, and PDF generation — all in a single deployable codebase.

## Technical Context

**Language/Version**: PHP 8.2+ (Laravel 11), Dart 3.x (Flutter stable channel)  
**Primary Dependencies**: Laravel 11, Laravel Sanctum (auth), Spatie Laravel-Permission (RBAC), dompdf 2.x (PDF), Laravel Queues (cron-compatible), Riverpod (Flutter state), mysql2 driver  
**Storage**: MySQL 8.x; one database per tenant; central `hexbase_central` DB for tenant registry; migration-managed schema per tenant  
**Testing**: PHPUnit (Laravel feature + unit tests); flutter_test (widget + integration); GST-critical paths require integration tests covering double-entry balance and tax calculation  
**Target Platform**: Shared hosting (PHP 8.2+, MySQL 8.x, Composer) for API; Flutter Web + Android + iOS + Windows for frontend; Docker for dev/CI only  
**Project Type**: REST API (web-service) + cross-platform mobile/desktop app  
**Performance Goals**: Single-document PDF < 10 s on shared hosting (SC-011); search < 2 s for 10k records (SC-005); invoice creation workflow < 3 min end-to-end (SC-001)  
**Constraints**: No Docker in production; shared hosting without daemon processes — queues MUST run via cron; no multi-currency; no e-invoice/e-way bill in Phase 1; max 10 concurrent users per tenant; no offline mode in Phase 1  
**Scale/Scope**: ~10k master records per tenant, up to 10 concurrent users, ~55+ screens (billing, masters, reports, admin)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principle | Gate Question | Status |
|---|-----------|---------------|--------|
| I | API-First Architecture | Does this feature keep all business logic in the Laravel API? Does the Flutter frontend consume only REST endpoints? | ✅ |
| II | GST Compliance | Does this feature leave all GST-critical schema columns (HSN/SAC, tax rates, CGST/SGST/IGST, place of supply, invoice type, ITC) unchanged and mandatory? | ✅ |
| III | Config-Driven Customisation | Are any client-specific variations handled via metadata/JSON definition tables rather than code or schema forks? | ✅ |
| IV | Multi-Tenancy | Does this feature respect tenant database isolation? Is no cross-tenant data access possible? | ✅ |
| V | Accounting Integrity | If this feature creates financial transactions, does it produce balanced double-entry ledger postings automatically? | ✅ |
| VI | Security & Auditability | Are API endpoints protected by role-based access control? Are sensitive changes audit-logged with user and timestamp? | ✅ |
| VII | Keyboard-First UX | If this feature adds forms or grids, do they support Tab navigation, search-first field selection, and auto-row creation? | ✅ |

> All principles PASS. This is a greenfield build — every design decision documented in research.md and data-model.md is made with all seven principles as hard constraints.

**Post-Phase-1 Re-check**: ✅ — data-model.md preserves fixed GST columns; contracts/ enforce RBAC on all endpoints; metadata tables (custom_field_definitions, line_column_definitions) serve all client customisation; each tenant DB is isolated; all financial entities map to double-entry postings; Flutter forms are designed keyboard-first per constitution VII.

## Project Structure

### Documentation (this feature)

```text
specs/001-hexbase-retail-full-app/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── api-overview.md
│   ├── auth.md
│   ├── masters.md
│   ├── sales.md
│   ├── purchases.md
│   ├── receipts-payments.md
│   ├── reports.md
│   └── admin.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
backend/                          # Laravel 11 REST API
├── app/
│   ├── Http/
│   │   ├── Controllers/Api/V1/   # All API controllers (versioned)
│   │   ├── Middleware/           # TenantResolver, Authenticate, RoleCheck
│   │   └── Requests/            # Form request validation classes
│   ├── Models/                  # Eloquent models (per-tenant DB)
│   ├── Services/                # Business logic: AccountingEngine, GstCalculator, PdfService
│   ├── Jobs/                    # Queued jobs: GeneratePdfJob, BackupJob
│   └── Policies/                # RBAC policies per resource
├── config/
│   └── tenancy.php              # Tenant resolution config
├── database/
│   ├── migrations/central/      # Central DB migrations (tenants table)
│   └── migrations/tenant/       # Per-tenant migrations (all business tables)
├── routes/
│   └── api.php                  # Versioned API routes (v1)
└── tests/
    ├── Feature/                 # API endpoint tests (Auth, Invoice, GST)
    └── Unit/                    # AccountingEngine, GstCalculator unit tests

frontend/                         # Flutter cross-platform app
├── lib/
│   ├── features/                # Feature-first layout
│   │   ├── auth/
│   │   ├── customers/
│   │   ├── vendors/
│   │   ├── products/
│   │   ├── sales_invoice/
│   │   ├── purchase_invoice/
│   │   ├── receipts/
│   │   ├── payments/
│   │   ├── quotations/
│   │   ├── purchase_orders/
│   │   ├── delivery_challans/
│   │   ├── expenses/
│   │   ├── credit_notes/
│   │   ├── debit_notes/
│   │   ├── reports/
│   │   └── admin/
│   ├── shared/                  # Shared widgets, keyboard nav utilities
│   │   ├── widgets/
│   │   └── keyboard/
│   ├── core/                    # API client, auth, tenant, error handling
│   └── main.dart
└── test/
    ├── widget/
    └── integration/
```

**Structure Decision**: Mobile + API layout (Option 3 adapted). Backend is Laravel API under `backend/`; frontend is Flutter under `frontend/`. The two are independently deployable — API to shared hosting, Flutter to app stores and web.
