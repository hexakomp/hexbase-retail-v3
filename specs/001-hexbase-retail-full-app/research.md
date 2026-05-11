# Research: Hexbase-Retail — Phase 0 Findings

**Branch**: `001-hexbase-retail-full-app` | **Date**: 2026-05-10  
**Resolves**: All NEEDS CLARIFICATION items from Technical Context in plan.md

---

## R-001: Multi-Tenancy Package Selection

**Decision**: Custom `TenantResolver` middleware + dynamic database connection switching using Laravel's `Config::set('database.connections.tenant', ...)` pattern — **without** Spatie Laravel-Multitenancy package.

**Rationale**:
- Spatie Laravel-Multitenancy adds ~8 additional abstractions (Tenant models, bootstrappers, task pipelines). For a system where tenancy is resolved purely by subdomain/tenant-code at the HTTP middleware layer, this overhead adds complexity without benefit.
- The custom approach: one central DB (`hexbase_central`) holds a `tenants` table; `TenantResolver` middleware reads subdomain/`X-Tenant-Code` header, looks up the tenant record, calls `DB::purge('tenant')` and `Config::set()` to point the `tenant` connection at the correct database, then sets a `app('tenant')` singleton for the request lifecycle.
- All Eloquent models extend a `TenantModel` base class that forces the `tenant` DB connection, ensuring no accidental cross-tenant queries.
- This is the approach used by several production Laravel SaaS systems on shared hosting and is fully compatible with shared hosting (no daemon required for middleware).

**Alternatives Considered**:
- Spatie Laravel-Multitenancy: Rejected — unnecessary abstraction layer for this use case; limited docs for separate-DB + shared-hosting without queue daemons.
- Single database with `tenant_id` column (row-level isolation): Rejected — constitution principle IV mandates separate databases; row-level isolation does not provide the same data boundary guarantees.

---

## R-002: PDF Generation Approach

**Decision**: **dompdf 2.x** rendered synchronously for single-document PDFs (invoices, quotations, POs, DCs, credit/debit notes); queued via Laravel cron-compatible queue for batch/report PDFs. PDF is returned as a base64 data URI or streamed inline; no blocking of the main UI request for documents < 10 s.

**Rationale**:
- dompdf 2.x is PHP-native, requires no additional server software, and works on shared hosting without wkhtmltopdf binary installation.
- tcpdf is lower-level and requires more manual layout code; dompdf's HTML+CSS rendering is faster to template for invoice-style documents.
- For single-document PDFs on typical shared hosting, dompdf renders a ~5-line invoice in 2–4 s, comfortably within the SC-011 10-second target.
- Queued PDF jobs (via `php artisan queue:work --stop-when-empty` triggered by cron every minute) handle report PDFs and large batch exports without blocking user requests.
- Each PDF template is stored as a Blade view; the `PdfService` loads the correct tenant template, passes transaction data, and calls `Dompdf\Dompdf::render()`.

**Alternatives Considered**:
- wkhtmltopdf / headless Chrome: Rejected — cannot install binaries on shared hosting.
- tcpdf: Rejected — more verbose API; HTML-to-PDF rendering via dompdf is faster for invoice templates.
- Async-only (always queue): Rejected — adds polling complexity on the Flutter side; single documents can render synchronously within the 10-second constraint.

---

## R-003: Double-Entry Accounting Engine

**Decision**: **Custom `AccountingEngine` service class** in `app/Services/AccountingEngine.php` — no third-party accounting package.

**Rationale**:
- The existing packages (e.g., `scottlaurent/accounting`) are designed around Laravel 5/6 patterns and lack GST-specific ledger types (CGST payable, SGST payable, IGST payable, ITC receivable).
- A custom `AccountingEngine` gives full control over ledger entry rules, supports Indian GST ledger chart of accounts, and can enforce the double-entry balance check before any `DB::commit()`.
- Implementation: `AccountingEngine::post(Transaction $txn, array $lines): void` — builds debit/credit pairs, validates `sum(debits) === sum(credits)`, and bulk-inserts into `ledger_entries`. Any imbalance throws `AccountingImbalanceException` (which triggers the activity log + admin email alert per FR-044/FR-045).
- The chart of accounts is seeded per tenant on onboarding; ledger types are fixed (cash, bank, sales, purchase, receivable, payable, tax, expense, stock).

**Alternatives Considered**:
- `scottlaurent/accounting` package: Rejected — outdated; no GST ledger types; would require forking.
- Manual journal UI (user creates entries): Rejected — spec mandates automatic postings; no manual entry screen needed for Phase 1.

---

## R-004: GST Calculation Rules (Indian GST)

**Decision**: All tax calculations performed **server-side** in `app/Services/GstCalculator.php`; Flutter displays server-returned values only.

**Key rules implemented**:
- **Place of Supply determination**: If seller's state code == buyer's place of supply state code → intra-state → apply CGST (half rate) + SGST (half rate). If different → inter-state → apply IGST (full rate).
- **Invoice types**: B2B (registered buyer, GSTIN required), B2C (unregistered buyer, aggregate B2C rules apply), Export (IGST zero-rated or with payment), SEZ (zero-rated with/without payment of IGST).
- **Taxable value**: `(quantity × rate) - discount_amount`. Tax is always on taxable value, not on MRP or gross.
- **Cess**: Applied on taxable value at the cess rate stored per product; summed separately.
- **Round-off**: `round_off = grand_total_rounded - grand_total_exact`; posted as a separate ledger entry to a Round-Off account.
- **Reverse Charge**: Flagged at invoice level; does not alter CGST/SGST/IGST amounts displayed but affects GSTR-3B reporting bucket.
- **ITC Eligibility**: Stored per purchase line; only eligible lines aggregate into ITC register (FR-020).

**Alternatives Considered**:
- Frontend tax calculation (Flutter): Rejected — violates Constitution Principle I (API-first) and II (GST compliance must be server-authoritative).

---

## R-005: Laravel Queue on Shared Hosting (No Daemon)

**Decision**: Use `php artisan queue:work --stop-when-empty` triggered via **cron every minute** (standard cPanel cron job).

**Rationale**:
- Shared hosting providers (cPanel-based) support cron jobs but not persistent daemon processes.
- `--stop-when-empty` processes all pending jobs in the queue and exits cleanly, preventing zombie processes.
- The queue driver is `database` (no Redis on shared hosting); the `jobs` table is part of the central DB or tenant DB depending on job type.
- PDF generation jobs use a 30-second timeout with 2 retries; backup jobs use a 300-second timeout.
- For single-document PDFs, the synchronous path is used (no queue needed) — queue is reserved for report exports and backup jobs.

**Alternatives Considered**:
- Redis + Supervisor: Rejected — not available on shared hosting without VPS upgrade.
- Sync queue driver: Rejected — blocks the HTTP request for backup jobs (potentially minutes).

---

## R-006: Flutter State Management for Form-Heavy Invoice Entry

**Decision**: **Riverpod 2.x** with `StateNotifier` / `AsyncNotifier` per feature module; form state kept in `InvoiceFormNotifier`; line items as an immutable list updated via `copyWith`.

**Rationale**:
- Riverpod provides compile-safe provider references, testable state notifiers, and clean separation between UI and business logic — critical for a form-heavy app with 50+ screens.
- `InvoiceFormNotifier` manages: customer selection, line item list (add, edit, remove, reorder), tax calculation trigger (calls API `POST /v1/invoices/calculate` on line change), form validation state.
- Keyboard navigation state (focus nodes, Tab order, Enter-as-Tab setting) is handled in a shared `KeyboardNavigationController` provider, applied uniformly to all data-entry grids.
- Auto-row creation: when the last column of the last row loses focus via Tab, the notifier appends a new empty line and focuses the first field of the new row.

**Alternatives Considered**:
- BLoC/Cubit: Viable but more boilerplate for 50+ screens; Riverpod is already mandated by constitution.
- flutter_form_builder: Useful for simple forms; rejected for line-item grids where custom keyboard handling is required.

---

## R-007: Tenant Database Provisioning

**Decision**: Tenant onboarding is an **admin API action** (`POST /v1/admin/tenants`) that: (1) creates a record in `hexbase_central.tenants`, (2) creates a new MySQL database using `CREATE DATABASE`, (3) runs all tenant migrations against the new DB using `php artisan migrate --database=tenant_onboard`, (4) seeds default chart of accounts, default roles/permissions, and numbering sequences.

**Rationale**:
- This matches the SC-004 requirement: "new tenant onboarded within one working day by an administrator without developer involvement."
- The API call is restricted to a super-admin role (not tenant-level Administrator).
- Database credentials used for provisioning are stored in `config/tenancy.php` and are separate from per-tenant runtime credentials.
- Each tenant DB user is created with `GRANT` limited to their own database, enforcing OS-level isolation.

**Alternatives Considered**:
- Manual DBA provisioning: Rejected — violates SC-004 (must not require developer involvement).
- Shared schema with `tenant_id` prefix: Rejected — violates Constitution Principle IV.

---

## R-008: Stock Valuation Method

**Decision**: **Weighted Average Cost (WAC)** method.

**Rationale**:
- The spec's assumptions section explicitly states: "Stock valuation uses a simple average cost method unless the PRD specifies otherwise."
- WAC is simpler to implement than FIFO/LIFO (no lot tracking required), suitable for small shops, and sufficient for inventory valuation summary reports.
- Average cost is recalculated on every purchase invoice posting: `new_avg_cost = (current_stock × current_avg_cost + received_qty × purchase_rate) / (current_stock + received_qty)`.
- Sales reduce stock at the current average cost (no per-lot tracking).

**Alternatives Considered**:
- FIFO: More accurate but requires lot/batch tracking — over-engineered for Phase 1 small-shop scope.
- LIFO: Not permitted under Indian accounting standards (AS-2).

---

## R-009: Backup Storage Integration

**Decision**: **Google Drive via Laravel Google Drive filesystem disk** (using `nao-pon/flysystem-google-drive` adapter) as the primary cloud backup destination; configurable per tenant. Additionally, direct **ZIP download** from admin UI (FR-034a) and **ZIP upload restore** (FR-034b).

**Rationale**:
- Google Drive is the most common cloud storage used by Indian small businesses; the PRD explicitly mentions it.
- The backup job: (1) dumps the tenant DB using `mysqldump` via `Symfony\Component\Process\Process`, (2) archives uploaded files and templates, (3) creates a ZIP, (4) uploads to Drive. The same ZIP is also available for direct HTTP download.
- The restore workflow: admin uploads ZIP via `POST /v1/admin/restore`, the system extracts, validates structure, shows a confirmation payload, and on confirmation (`POST /v1/admin/restore/confirm`) restores DB and files.

**Alternatives Considered**:
- S3: Valid option but less common in Indian small business context; can be added as a second driver in Phase 2.
- Full server backup (cPanel): Not application-controlled; cannot satisfy FR-034a (download from admin UI).

---

## Summary: All Unknowns Resolved

| ID | Unknown | Resolution |
|----|---------|-----------|
| R-001 | Multi-tenancy package | Custom TenantResolver middleware |
| R-002 | PDF generation | dompdf 2.x, sync for single docs, queued for reports |
| R-003 | Accounting engine | Custom AccountingEngine service |
| R-004 | GST calculation rules | Server-side GstCalculator; intra/inter-state logic documented |
| R-005 | Queue on shared hosting | Database queue + cron `--stop-when-empty` |
| R-006 | Flutter state management | Riverpod 2.x with StateNotifier per feature |
| R-007 | Tenant provisioning | Admin API action with CREATE DATABASE + migrate |
| R-008 | Stock valuation | Weighted Average Cost |
| R-009 | Backup storage | Google Drive + ZIP download/upload |
