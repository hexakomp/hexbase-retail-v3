---
description: "Task list for Hexbase-Retail â€” Small Shop GST Accounting System"
---

# Tasks: Hexbase-Retail â€” Small Shop GST Accounting System

**Input**: Design documents from `/specs/001-hexbase-retail-full-app/`
**Branch**: `001-hexbase-retail-full-app` | **Date**: 2026-05-10
**Stack**: Laravel 11 (backend/) + Flutter 3.x (frontend/)
**Prerequisites**: plan.md âœ… | spec.md âœ… | data-model.md âœ… | research.md âœ… | contracts/ âœ…

## Format: `[ID] [P?] [Story?] Description â€” file path`

- **[P]**: Parallelizable (different files, no dependency on incomplete tasks)
- **[Story]**: User story label (US1â€“US9)
- No test tasks â€” not requested in specification

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize both projects with correct structure, dependencies, and environment.

- [X] T001 Initialize Laravel 11 project with Composer in backend/ (requires PHP 8.2+)
- [X] T002 [P] Install Laravel backend dependencies: sanctum, spatie/laravel-permission, dompdf/dompdf 2.x, nao-pon/flysystem-google-drive â€” backend/composer.json
- [X] T003 [P] Configure dual database connections (central + tenant) and tenancy settings â€” backend/config/tenancy.php + backend/config/database.php
- [X] T004 [P] Configure Laravel Queue with database driver for cron-compatible `--stop-when-empty` operation â€” backend/config/queue.php
- [X] T005 [P] Set up versioned API route file structure with Sanctum middleware groups â€” backend/routes/api.php
- [X] T006 [P] Configure base API exception handler returning standard `{data, meta, message}` envelope â€” backend/app/Exceptions/Handler.php
- [X] T007 [P] Initialize Flutter project targeting Android, iOS, Windows, and web platforms â€” frontend/
- [X] T008 [P] Install Flutter dependencies: flutter_riverpod 2.x, riverpod_annotation, dio, go_router, shared_preferences, file_picker â€” frontend/pubspec.yaml
- [X] T009 [P] Set up Flutter app theme, MaterialApp shell, and go_router navigation structure â€” frontend/lib/main.dart + frontend/lib/core/routes.dart
- [X] T010 [P] Create core Dio API client with auth token interceptor and standard error handling â€” frontend/lib/core/api_client.dart
- [X] T011 [P] Create Flutter environment configuration (API base URL, tenant code) â€” frontend/lib/core/config.dart


**Checkpoint**: Both projects boot. Backend returns 200 on health check. Flutter renders app shell.

---

## Phase 2: Foundation (Blocking Prerequisites)

**Purpose**: Core infrastructure MUST be complete before any user story. Covers multi-tenancy, auth, RBAC, all DB migrations, core services, and shared Flutter widgets.

**âš ï¸ CRITICAL**: No user story work begins until this phase is complete.

### Backend Foundation

- [X] T012 Implement `TenantResolver` middleware: resolve tenant from subdomain / `X-Tenant-Code` header, lookup `hexbase_central.tenants`, switch `tenant` DB connection via `Config::set` â€” backend/app/Http/Middleware/TenantResolver.php
- [X] T013 [P] Create `TenantModel` abstract base class that forces the `tenant` DB connection on all Eloquent models â€” backend/app/Models/TenantModel.php
- [X] T014 Register `TenantResolver` in middleware stack and bind `app('tenant')` singleton for request lifecycle â€” backend/bootstrap/app.php
- [X] T015 [P] Create central DB migration: `tenants` table (id, name, code, subdomain, db_name, db_host, db_username, db_password encrypted, plan, active) â€” backend/database/migrations/central/2026_05_10_000001_create_tenants_table.php
- [X] T016 [P] Create tenant DB migrations batch 1 â€” auth & company: `users`, `personal_access_tokens`, `company_settings`, `bank_accounts`, `numbering_sequences`, Spatie permission tables â€” backend/database/migrations/tenant/
- [X] T017 [P] Create tenant DB migrations batch 2 â€” masters: `customers`, `vendors`, `products`, `price_lists` â€” backend/database/migrations/tenant/
- [X] T018 Create tenant DB migrations batch 3 â€” sales: `sales_invoices`, `sales_invoice_lines`, `quotations`, `quotation_lines`, `delivery_challans`, `delivery_challan_lines`, `credit_notes`, `credit_note_lines` â€” backend/database/migrations/tenant/
- [X] T019 [P] Create tenant DB migrations batch 4 â€” purchases: `purchase_invoices`, `purchase_invoice_lines`, `purchase_orders`, `purchase_order_lines`, `debit_notes`, `debit_note_lines` â€” backend/database/migrations/tenant/
- [X] T020 [P] Create tenant DB migrations batch 5 â€” finance: `receipts`, `receipt_allocations`, `payments`, `payment_allocations`, `expenses` â€” backend/database/migrations/tenant/
- [X] T021 [P] Create tenant DB migrations batch 6 â€” accounting & config: `chart_of_accounts`, `ledger_entries`, `inventory_movements`, `activity_log`, `custom_field_definitions`, `line_column_definitions` â€” backend/database/migrations/tenant/
- [X] T022 Implement Sanctum authentication: login (rate-limited 10/min), logout, profile endpoints â€” backend/app/Http/Controllers/Api/V1/AuthController.php
- [X] T023 [P] Seed Spatie roles and permissions (admin, acc, billing, view) with granular endpoint permissions per contracts â€” backend/database/seeders/RolesAndPermissionsSeeder.php
- [X] T024 [P] Seed chart of accounts with GST ledger types (cash, bank, sales, purchase, receivable, payable, cgst-payable, sgst-payable, igst-payable, itc-receivable, expense, stock, round-off) â€” backend/database/seeders/ChartOfAccountsSeeder.php
- [X] T025 Implement `AccountingEngine` service: accept transaction + debit/credit line array, validate `sum(debits) == sum(credits)`, bulk-insert to `ledger_entries`, throw `AccountingImbalanceException` on mismatch â€” backend/app/Services/AccountingEngine.php
- [X] T026 [P] Implement `GstCalculator` service: place-of-supply determination (intra/inter-state), split GST rate to CGST+SGST or IGST, compute taxable value `(qty Ã— rate) âˆ’ discount`, cess, round-off â€” backend/app/Services/GstCalculator.php
- [X] T027 [P] Implement `NumberingSequenceService`: atomic increment with `lockForUpdate()`, format with prefix/suffix/padding per module and financial year â€” backend/app/Services/NumberingSequenceService.php
- [X] T028 [P] Implement `PdfService`: load Blade template, inject tenant data, call `Dompdf::render()` synchronously for single documents, dispatch `GeneratePdfJob` for batch/report PDFs â€” backend/app/Services/PdfService.php
- [X] T029 [P] Implement `GeneratePdfJob` queued job (30s timeout, 2 retries): on `failed()` hook dispatch email alert to `company_settings.admin_alert_email` with job class, document type, and error message â€” backend/app/Jobs/GeneratePdfJob.php
- [X] T030 Implement `TenantProvisioningService`: CREATE DATABASE, per-tenant MySQL GRANT, run tenant migrations, run seeders (roles, chart of accounts, default numbering sequences) â€” backend/app/Services/TenantProvisioningService.php
- [X] T031 [P] Implement `TenantController` admin endpoint `POST /v1/admin/tenants` (super-admin only) calling `TenantProvisioningService` â€” backend/app/Http/Controllers/Api/V1/Admin/TenantController.php
- [X] T032 [P] Create `Customer`, `Vendor`, `Product` Eloquent models with all GST-critical columns, fillable arrays, fulltext index scopes for search â€” backend/app/Models/Customer.php + Vendor.php + Product.php
- [X] T033 Create `CustomerController` and `VendorController` with full CRUD (index with search, store, show, update, destroy) and GSTIN duplicate-check on store/update â€” backend/app/Http/Controllers/Api/V1/CustomerController.php + VendorController.php
- [X] T034 [P] Create `ProductController` with full CRUD and barcode+name search endpoint â€” backend/app/Http/Controllers/Api/V1/ProductController.php
- [X] T035 [P] Create form request validation classes for Customer, Vendor, Product (GSTIN format regex, required fields, unique constraints) â€” backend/app/Http/Requests/
- [X] T036 [P] Register all master API routes (customers, vendors, products) with role middleware â€” backend/routes/api.php

### Flutter Foundation

- [X] T037 Implement auth feature: login screen, `AuthNotifier` (Riverpod), Sanctum token storage via `shared_preferences`, auto-redirect on token expiry â€” frontend/lib/features/auth/
- [X] T038 [P] Create `TenantProvider` (Riverpod): tenant code from app config, injected into all API headers â€” frontend/lib/core/tenant_provider.dart
- [X] T039 [P] Create `KeyboardNavigationController` (shared Riverpod provider): focus node management, Tab-as-Enter toggle, auto-scroll to focused field â€” frontend/lib/shared/keyboard/keyboard_navigation_controller.dart
- [X] T040 [P] Create `DataGrid` shared widget: keyboard-first line-item table, Tab navigation across cells, auto-row creation on Tab past last column â€” frontend/lib/shared/widgets/data_grid.dart
- [X] T041 [P] Create `SearchableDropdown` shared widget: debounced API search, keyboard-navigable results, select-on-Enter â€” frontend/lib/shared/widgets/searchable_dropdown.dart
- [X] T042 [P] Create `AppScaffold` shared widget with navigation drawer listing all modules â€” frontend/lib/shared/widgets/app_scaffold.dart

**Checkpoint**: Foundation ready. Auth works end-to-end. Customer/Vendor/Product CRUD APIs reachable. Flutter app navigates to login and home.

---

## Phase 3: User Story 1 â€” Fast Sales Billing with GST (Priority: P1) ðŸŽ¯ MVP

**Goal**: Billing operator creates a GST-compliant sales invoice, views tax breakup, and downloads PDF.

**Independent Test**: Create customer â†’ Create product with HSN + 18% GST â†’ Create sales invoice with 2 line items â†’ Verify CGST 9% + SGST 9% (intra-state) or IGST 18% (inter-state) â†’ Verify PDF downloads within 10 seconds.

### Backend â€” US1

- [X] T042a [P] Create Docker Compose dev environment: `mysql` service (MySQL 8.0 with central + tenant DBs pre-created), shared `.env` for local connection strings, README for setup â€” docker-compose.yml + backend/.env + README.md
- [X] T043 [P] [US1] Create `SalesInvoice` and `SalesInvoiceLine` Eloquent models with all GST-critical columns, relationships, and `TenantModel` base â€” backend/app/Models/SalesInvoice.php + SalesInvoiceLine.php
- [X] T044 [US1] Implement `SalesInvoiceService`: draft-create, line GST calculation via `GstCalculator`, header totals aggregation, post (statusâ†’posted, double-entry via `AccountingEngine`, stock deduction, `outstanding_amount` set), cancel (soft-cancel, reverse ledger entries) â€” backend/app/Services/SalesInvoiceService.php
- [X] T045 [US1] Implement `SalesInvoiceController`: `index` (paginated list, search by number/customer/date), `store` (draft), `show`, `update` (draft only), `post`, `cancel`, `pdf` â€” backend/app/Http/Controllers/Api/V1/SalesInvoiceController.php
- [X] T046 [P] [US1] Implement `POST /v1/invoices/calculate` real-time tax preview endpoint (stateless, returns line-level and header tax totals without saving) â€” backend/app/Http/Controllers/Api/V1/SalesInvoiceController.php
- [X] T047 [P] [US1] Create `SalesInvoiceRequest` form request validation (required GST fields, place_of_supply, invoice_type, line item constraints) â€” backend/app/Http/Requests/SalesInvoiceRequest.php
- [X] T048 [P] [US1] Create Blade PDF template for sales invoice (GST-compliant layout: GSTIN, HSN/SAC per line, CGST/SGST/IGST breakup, place of supply, tax summary table) â€” backend/resources/views/pdf/sales-invoice.blade.php
- [X] T049 [P] [US1] Register sales invoice API routes with role middleware (billing, acc, admin) â€” backend/routes/api.php

### Flutter â€” US1

- [X] T050 [P] [US1] Implement `SalesInvoiceRepository` (Dio calls) and `InvoiceListNotifier` (Riverpod `AsyncNotifier`) â€” frontend/lib/features/sales_invoice/providers/invoice_list_provider.dart
- [X] T051 [P] [US1] Implement `InvoiceFormNotifier` (Riverpod `StateNotifier`): customer selection, line item CRUD (add/edit/remove/reorder), call calculate API on line change, validation state â€” frontend/lib/features/sales_invoice/providers/invoice_form_provider.dart
- [X] T052 [P] [US1] Implement Sales Invoice list screen with search bar, status filter chips, and FAB for new invoice â€” frontend/lib/features/sales_invoice/screens/sales_invoice_list_screen.dart
- [X] T053 [US1] Implement Sales Invoice form screen: `SearchableDropdown` for customer, keyboard-first `DataGrid` for line items (product search by name/barcode, qty, rate, discount, auto-calculated tax columns), tax summary footer, post/save actions â€” frontend/lib/features/sales_invoice/screens/sales_invoice_form_screen.dart
- [X] T054 [P] [US1] Implement PDF view/download screen: call `pdf` endpoint, show `CircularProgressIndicator` loading state during generation (non-blocking), display inline PDF viewer (`flutter_pdfview` or `syncfusion_flutter_pdfviewer`) or open share sheet on completion; handle timeout/error states â€” frontend/lib/features/sales_invoice/screens/sales_invoice_pdf_screen.dart

**Checkpoint**: US1 fully functional â€” invoice creates, posts, computes GST correctly, PDF downloads < 10 s.

---

## Phase 4: User Story 2 â€” Purchase Invoice Entry with ITC Tracking (Priority: P2)

**Goal**: Accountant enters vendor purchase invoice with ITC eligibility per line, updates payables.

**Independent Test**: Select vendor â†’ Enter vendor invoice number â†’ Add line items with GST breakup and mark ITC eligibility per line â†’ Post â†’ Verify payable balance updated â†’ Verify ITC register shows eligible lines only.

### Backend â€” US2

- [X] T055 [P] [US2] Create `PurchaseInvoice` and `PurchaseInvoiceLine` Eloquent models with `itc_eligible`, `reverse_charge`, `attachment_path` columns â€” backend/app/Models/PurchaseInvoice.php + PurchaseInvoiceLine.php
- [X] T056 [US2] Implement `PurchaseInvoiceService`: post (double-entry via `AccountingEngine` â€” debit purchase/expense, credit accounts-payable; stock update via WAC; ITC registration on eligible lines; PO status update when linked), cancel â€” backend/app/Services/PurchaseInvoiceService.php
- [X] T057 [US2] Implement `PurchaseInvoiceController`: `index`, `store`, `show`, `update`, `post`, `cancel`, `attach` (file upload to `attachment_path`) â€” backend/app/Http/Controllers/Api/V1/PurchaseInvoiceController.php
- [X] T058 [P] [US2] Create `PurchaseInvoiceRequest` form request validation â€” backend/app/Http/Requests/PurchaseInvoiceRequest.php
- [X] T059 [P] [US2] Register purchase invoice API routes with role middleware (acc, admin) â€” backend/routes/api.php

### Flutter â€” US2

- [X] T060 [P] [US2] Implement `PurchaseInvoiceRepository` and `PurchaseInvoiceListNotifier` (Riverpod) â€” frontend/lib/features/purchase_invoice/providers/
- [X] T061 [P] [US2] Implement Purchase Invoice list screen â€” frontend/lib/features/purchase_invoice/screens/purchase_invoice_list_screen.dart
- [X] T062 [US2] Implement Purchase Invoice form screen: vendor search, vendor invoice number/date fields, line-item `DataGrid` with per-line ITC eligibility toggle and reverse-charge header switch, file attachment picker â€” frontend/lib/features/purchase_invoice/screens/purchase_invoice_form_screen.dart

**Checkpoint**: US2 functional â€” purchase posts, payable balance updates, ITC register populated.

---

## Phase 5: User Story 3 â€” Receipt and Payment Allocation (Priority: P3)

**Goal**: Accountant records customer receipt, allocates to outstanding invoices, updates receivables.

**Independent Test**: Enter receipt amount for customer â†’ Allocate against a specific posted sales invoice â†’ Verify invoice `outstanding_amount` reduced â†’ Verify bank/cash ledger updated.

### Backend â€” US3

- [X] T063 [P] [US3] Create `Receipt` and `ReceiptAllocation` Eloquent models â€” backend/app/Models/Receipt.php + ReceiptAllocation.php
- [X] T064 [US3] Implement `ReceiptService`: post (validate total allocation â‰¤ receipt amount, update each allocated `sales_invoice.outstanding_amount`, store advance remainder, double-entry via `AccountingEngine` â€” debit cash/bank, credit receivable), cancel â€” backend/app/Services/ReceiptService.php
- [X] T065 [US3] Implement `ReceiptController`: `index`, `store` (with allocations array), `show`, `post`, `cancel` â€” backend/app/Http/Controllers/Api/V1/ReceiptController.php
- [X] T066 [P] [US3] Register receipt API routes â€” backend/routes/api.php

### Flutter â€” US3

- [X] T067 [P] [US3] Implement `ReceiptRepository` and `ReceiptListNotifier` â€” frontend/lib/features/receipts/providers/
- [X] T068 [P] [US3] Implement Receipts list screen â€” frontend/lib/features/receipts/screens/receipt_list_screen.dart
- [X] T069 [US3] Implement Receipt form screen: customer search, payment mode selector, bank account selector, invoice allocation table (shows outstanding invoices, allows partial allocation per invoice, running balance footer) â€” frontend/lib/features/receipts/screens/receipt_form_screen.dart

**Checkpoint**: US3 functional â€” receipt posts, invoice outstanding drops correctly, advance tracked.

---

## Phase 6: User Story 4 â€” Vendor Payment Processing (Priority: P4)

**Goal**: Accountant records payment to vendor, allocates against outstanding purchase invoices, updates payables.

**Independent Test**: Enter payment for vendor â†’ Allocate against a posted purchase invoice â†’ Verify payable balance decreases â†’ Verify bank/cash ledger updated.

### Backend â€” US4

- [X] T070 [P] [US4] Create `Payment` and `PaymentAllocation` Eloquent models â€” backend/app/Models/Payment.php + PaymentAllocation.php
- [X] T071 [US4] Implement `PaymentService`: post (validate allocation â‰¤ payment amount, update `purchase_invoice.outstanding_amount`, store advance, double-entry â€” debit payable, credit cash/bank), cancel â€” backend/app/Services/PaymentService.php
- [X] T072 [US4] Implement `PaymentController`: `index`, `store`, `show`, `post`, `cancel` â€” backend/app/Http/Controllers/Api/V1/PaymentController.php
- [X] T073 [P] [US4] Register payment API routes â€” backend/routes/api.php

### Flutter â€” US4

- [X] T074 [P] [US4] Implement `PaymentRepository` and `PaymentListNotifier` â€” frontend/lib/features/payments/providers/
- [X] T075 [P] [US4] Implement Payments list screen â€” frontend/lib/features/payments/screens/payment_list_screen.dart
- [X] T076 [US4] Implement Payment form screen: vendor search, payment mode selector, purchase invoice allocation table with outstanding amounts â€” frontend/lib/features/payments/screens/payment_form_screen.dart

**Checkpoint**: US4 functional â€” payment posts, purchase invoice outstanding drops, advance tracked.

---

## Phase 7: User Story 5 â€” GST Report Generation (Priority: P5)

**Goal**: Accountant generates GSTR-1 classification summaries and GSTR-3B support data for a date range.

**Independent Test**: Post B2B invoices, B2C invoices, and purchase invoices with ITC in a month â†’ Generate GSTR-1 â†’ Verify B2B section has GSTIN + invoice-level detail â†’ Verify B2C is aggregated â†’ Verify HSN summary sums correctly â†’ Verify ITC register shows eligible amounts only.

### Backend â€” US5

- [X] T077 [P] [US5] Implement `GstReportService`: GSTR-1 B2B section (posted sales invoices with GSTIN, invoice-level CGST/SGST/IGST), GSTR-1 B2C aggregate, GSTR-1 document summary (all invoice types including credit notes â€” count, taxable value, tax amounts), GSTR-1 tax liability summary (net output tax by rate slab), GSTR-1 amendment section (credit notes and debit notes linked to original invoices per FR-043), HSN summary (group by `hsn_sac`, sum taxable/CGST/SGST/IGST), ITC register (eligible `purchase_invoice_lines` only), GSTR-3B support buckets, sales tax register, purchase tax register â€” backend/app/Services/GstReportService.php
- [X] T078 [US5] Implement `GstReportController`: `GET /v1/reports/gst/gstr1`, `GET /v1/reports/gst/gstr3b-support`, `GET /v1/reports/gst/hsn-summary`, `GET /v1/reports/gst/itc-register`, `GET /v1/reports/gst/sales-tax-register`, `GET /v1/reports/gst/purchase-tax-register` (all accept `from_date`, `to_date` query params) â€” backend/app/Http/Controllers/Api/V1/Reports/GstReportController.php
- [X] T079 [P] [US5] Register GST report API routes (view-only role allowed) â€” backend/routes/api.php

### Flutter â€” US5

- [X] T080 [P] [US5] Implement GST Reports Riverpod providers and repository â€” frontend/lib/features/reports/providers/gst_report_provider.dart
- [X] T081 [P] [US5] Implement GSTR-1 screen with date range picker and B2B / B2C / HSN Summary tab sections â€” frontend/lib/features/reports/screens/gstr1_screen.dart
- [X] T082 [P] [US5] Implement GSTR-3B support summary screen and ITC register screen â€” frontend/lib/features/reports/screens/gstr3b_screen.dart + itc_register_screen.dart
- [X] T139 [P] [US5] Implement Sales Tax Register and Purchase Tax Register Flutter screens with date range picker, tabular view of invoice-level tax columns (CGST/SGST/IGST), and PDF export action â€” frontend/lib/features/reports/screens/tax_register_screen.dart

**Checkpoint**: US5 functional â€” GST reports correctly categorize invoices; HSN summary totals match posted transactions.

---

## Phase 8: User Story 6 â€” Customer and Vendor Master Management (Priority: P6)

**Goal**: Full master CRUD with GSTIN validation, duplicate detection, credit terms, opening balances.

**Independent Test**: Create customer with GSTIN â†’ Attempt duplicate GSTIN â†’ See warning â†’ Edit credit limit â†’ Search by partial name â†’ Verify result within 2 s for 10k records.

### Backend â€” US6

- [X] T083 [US6] Enhance `CustomerController`: add GSTIN duplicate-check response field, opening balance type toggle, price list assignment, soft-delete; ensure `name` fulltext index search within 2 s â€” backend/app/Http/Controllers/Api/V1/CustomerController.php
- [X] T084 [P] [US6] Enhance `VendorController`: add TDS applicable flag, opening balance, soft-delete â€” backend/app/Http/Controllers/Api/V1/VendorController.php
- [X] T085 [P] [US6] Add `GET /v1/customers/search` and `GET /v1/vendors/search` fast-search endpoints (name/GSTIN, returns lightweight DTO for dropdowns) â€” backend/routes/api.php

### Flutter â€” US6

- [X] T086 [P] [US6] Implement Customer list screen: data table with search bar, active/inactive filter, add/edit navigation â€” frontend/lib/features/customers/screens/customer_list_screen.dart
- [X] T087 [US6] Implement Customer form screen: GSTIN field with format validation (15-char regex), duplicate warning snackbar/dialog, billing + shipping address sections, credit limit, opening balance â€” frontend/lib/features/customers/screens/customer_form_screen.dart
- [X] T088 [P] [US6] Implement Vendor list and form screens (similar structure to customer, includes TDS flag) â€” frontend/lib/features/vendors/screens/

**Checkpoint**: US6 functional â€” GSTIN duplicate detection works; partial-name search returns results.

---

## Phase 9: User Story 7 â€” Product and Service Master with Inventory (Priority: P7)

**Goal**: Product CRUD with HSN/SAC + GST rate; stock updates from invoice postings; reorder alerts.

**Independent Test**: Create product with HSN + 18% GST + min stock level â†’ Post purchase invoice (stock up) â†’ Post sales invoice (stock down) â†’ View stock summary â†’ Verify WAC recalculated â†’ Verify reorder alert when stock < min level.

### Backend â€” US7

- [X] T089 [US7] Implement `InventoryService`: WAC recalculation on purchase post `(current_stock Ã— avg_cost + received_qty Ã— rate) / (current_stock + received_qty)`, stock deduction on sales post, `InventoryMovement` record for each movement, reorder alert (log + admin email via `company_settings.admin_alert_email`) â€” backend/app/Services/InventoryService.php
- [X] T090 [P] [US7] Implement `InventoryMovement` Eloquent model â€” backend/app/Models/InventoryMovement.php
- [X] T091 [P] [US7] Implement `GET /v1/products/stock-summary` endpoint (paginated, filter by low-stock, search by name) â€” backend/app/Http/Controllers/Api/V1/ProductController.php
- [X] T092 [P] [US7] Implement `GET /v1/products/{id}/movements` inventory movement history endpoint â€” backend/app/Http/Controllers/Api/V1/ProductController.php
- [X] T137 [P] [US7] Implement manual stock adjustment endpoint `POST /v1/products/{id}/stock-adjustment` in `InventoryService` (accepts `quantity`, `adjustment_type` ENUM: increase/decrease, `reason`; records `InventoryMovement` with type=adjustment; updates `current_stock` and `avg_cost` if increase with cost; restricted to acc/admin roles) â€” backend/app/Http/Controllers/Api/V1/ProductController.php
- [X] T138 [P] [US7] Implement Flutter stock adjustment dialog on Stock Summary screen: quantity field, type toggle (increase/decrease), reason text field, confirm action â€” frontend/lib/features/products/screens/stock_summary_screen.dart

### Flutter â€” US7

- [X] T093 [P] [US7] Implement Products Riverpod providers and repository â€” frontend/lib/features/products/providers/
- [X] T094 [P] [US7] Implement Product list screen: search by name/barcode/HSN, goods/service type filter â€” frontend/lib/features/products/screens/product_list_screen.dart
- [X] T095 [US7] Implement Product form screen: HSN/SAC field, GST rate field, purchase/selling/MRP rates, `track_inventory` toggle (hides stock fields for services), min stock level, opening stock â€” frontend/lib/features/products/screens/product_form_screen.dart
- [X] T096 [P] [US7] Implement Stock Summary screen: data table with current stock, avg cost, low-stock highlight, drill-down to movement history â€” frontend/lib/features/products/screens/stock_summary_screen.dart

**Checkpoint**: US7 functional â€” stock updates after invoice posts; WAC recalculates; reorder alert fires.

---

## Phase 10: User Story 8 â€” Quotation to Invoice Conversion (Priority: P8)

**Goal**: Sales operator creates a quotation and converts it to a sales invoice in one action.

**Independent Test**: Create quotation â†’ Mark accepted â†’ Convert to invoice â†’ Verify all line items, HSN codes, rates, and customer details pre-populated â†’ Attempt conversion of expired quotation â†’ Verify warning shown.

### Backend â€” US8

- [X] T097 [P] [US8] Create `Quotation` and `QuotationLine` Eloquent models (mirrors sales invoice GST-critical columns) â€” backend/app/Models/Quotation.php + QuotationLine.php
- [X] T098 [US8] Implement `QuotationService`: draft/send/accept/reject status transitions, `convert` (checks `validity_date`, copies all lines + GST data to new `SalesInvoice` via `SalesInvoiceService::draft`, sets `converted_invoice_id`, status â†’ `converted`), expiry auto-update (cron or on-read) â€” backend/app/Services/QuotationService.php
- [X] T099 [US8] Implement `QuotationController`: `index`, `store`, `show`, `update`, `post` (statusâ†’sent), `convert` â€” backend/app/Http/Controllers/Api/V1/QuotationController.php
- [X] T100 [P] [US8] Create Blade PDF template for quotation â€” backend/resources/views/pdf/quotation.blade.php
- [X] T101 [P] [US8] Register quotation API routes â€” backend/routes/api.php

### Flutter â€” US8

- [X] T102 [P] [US8] Implement Quotations Riverpod providers and repository â€” frontend/lib/features/quotations/providers/
- [X] T103 [P] [US8] Implement Quotation list screen with status filter (draft/sent/accepted/converted/expired) â€” frontend/lib/features/quotations/screens/quotation_list_screen.dart
- [X] T104 [US8] Implement Quotation form screen: customer search, validity date picker, line-item `DataGrid`, status action buttons (Send / Accept / Convert to Invoice), expiry warning dialog on convert â€” frontend/lib/features/quotations/screens/quotation_form_screen.dart

**Checkpoint**: US8 functional â€” quotation converts to invoice with all data intact; expired quotation blocked.

---

## Phase 11: User Story 9 â€” Financial Reports and Ledger Views (Priority: P9)

**Goal**: Accountant views trial balance, P&L, balance sheet, day book, cash book, and customer/vendor ledger.

**Independent Test**: Post sales + purchase + payment transactions â†’ Generate trial balance â†’ Verify total debits equal total credits â†’ View P&L â†’ Verify correct gross margin â†’ View day book â†’ Verify all vouchers appear in date order.

### Backend â€” US9

- [X] T105 [P] [US9] Implement `FinancialReportService`: trial balance (group `ledger_entries` by `chart_of_accounts`, sum debits/credits), P&L (income âˆ’ expense from appropriate account groups), balance sheet (assets = liabilities + equity), day book (all vouchers by date), cash book / bank book (filter ledger entries by cash/bank account), sales register (all posted sales invoices with tax breakup), purchase register (all posted purchase invoices with ITC), cash flow summary (net cash in/out by category), ledger account drill-down â€” backend/app/Services/FinancialReportService.php
- [X] T106 [US9] Implement `FinancialReportController`: `GET /v1/reports/financial/trial-balance`, `/profit-loss`, `/balance-sheet`, `/day-book`, `/cash-book`, `/sales-register`, `/purchase-register`, `/cash-flow`, `/ledger/{account_id}` (all accept date range params) â€” backend/app/Http/Controllers/Api/V1/Reports/FinancialReportController.php
- [X] T107 [P] [US9] Register financial report API routes â€” backend/routes/api.php

### Flutter â€” US9

- [X] T108 [P] [US9] Implement Financial Reports Riverpod providers and repository â€” frontend/lib/features/reports/providers/financial_report_provider.dart
- [X] T109 [P] [US9] Implement Trial Balance screen: two-column table (debit/credit) with account group headings, totals row â€” frontend/lib/features/reports/screens/trial_balance_screen.dart
- [X] T110 [P] [US9] Implement P&L screen: income section, expense section, net profit/loss row â€” frontend/lib/features/reports/screens/profit_loss_screen.dart
- [X] T111 [P] [US9] Implement Balance Sheet screen: assets vs liabilities + equity layout â€” frontend/lib/features/reports/screens/balance_sheet_screen.dart
- [X] T112 [P] [US9] Implement Day Book and Cash Book screens: chronological voucher list with type, number, amount, narration â€” frontend/lib/features/reports/screens/day_book_screen.dart + cash_book_screen.dart

**Checkpoint**: US9 functional â€” trial balance debits equal credits; P&L gross margin correct.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Purpose**: Supporting modules, admin features, PDF templates, deployment hardening.

### Credit Notes & Debit Notes

- [X] T113 [P] Create `CreditNote` + `CreditNoteLine` and `DebitNote` + `DebitNoteLine` Eloquent models (mirror sales/purchase invoice with `original_invoice_id`, `reason`) â€” backend/app/Models/
- [X] T114 [P] Implement `CreditNoteController` and `DebitNoteController` (index, store, show, post, cancel, pdf) with `AccountingEngine` posting â€” backend/app/Http/Controllers/Api/V1/
- [X] T115 [P] Create Blade PDF templates for credit note and debit note â€” backend/resources/views/pdf/
- [X] T116 [P] Implement Credit Notes and Debit Notes Flutter screens: list screens (with filter by original invoice), form screens, and PDF view screen (loading indicator during generation per FR-026, inline viewer or share sheet) â€” frontend/lib/features/credit_notes/ + frontend/lib/features/debit_notes/

### Purchase Orders & Delivery Challans

- [X] T117 [P] Create `PurchaseOrder` + `PurchaseOrderLine` Eloquent models and `PurchaseOrderController` (index, store, show, update, cancel; PO status update on PI link) â€” backend/app/Http/Controllers/Api/V1/PurchaseOrderController.php
- [X] T118 [P] Create `DeliveryChallan` + `DeliveryChallanLine` Eloquent models and `DeliveryChallanController` (index, store, show, update, dispatch, cancel) â€” backend/app/Http/Controllers/Api/V1/DeliveryChallanController.php
- [X] T119 [P] Create Blade PDF templates for purchase order and delivery challan â€” backend/resources/views/pdf/
- [X] T120 [P] Implement Purchase Orders and Delivery Challans Flutter screens (list + form) â€” frontend/lib/features/purchase_orders/ + frontend/lib/features/delivery_challans/

### Expenses

- [X] T121 [P] Implement `Expense` model (columns: `expense_date`, `reference`, `vendor_id`, `account_id`, `amount`, `payment_mode` ENUM cash/bank/cheque, `bank_account_id`, `gst_applicable`, `gst_rate`, `cgst_amount`, `sgst_amount`, `igst_amount`, `itc_eligible`, `reverse_charge`, `narration`, `status`, soft-delete); implement `ExpenseController` (index, store, show, post, cancel with `AccountingEngine` posting to expense account) â€” backend/app/Http/Controllers/Api/V1/ExpenseController.php
- [X] T122 [P] Implement Expenses Flutter list and form screens â€” frontend/lib/features/expenses/

### Admin Module

- [X] T123 [P] Implement `CompanySettingsController` (GET/PUT company profile, logo upload, financial year, round-off method, admin alert email) â€” backend/app/Http/Controllers/Api/V1/Admin/CompanySettingsController.php
- [X] T124 [P] Implement `BankAccountController` (index, store, show, update, toggle active) â€” backend/app/Http/Controllers/Api/V1/Admin/BankAccountController.php
- [X] T125 [P] Implement `UsersController` (index, store, show, update, assign roles, deactivate) with Spatie role assignment â€” backend/app/Http/Controllers/Api/V1/Admin/UsersController.php
- [X] T126 [P] Implement `NumberingSequenceController` (index, store/update per module per year) â€” backend/app/Http/Controllers/Api/V1/Admin/NumberingSequenceController.php
- [X] T127 [P] Implement `ActivityLogController` (paginated log: user, action, model, old/new values) â€” backend/app/Http/Controllers/Api/V1/Admin/ActivityLogController.php
- [X] T128 [P] Implement `CustomFieldController` (definitions: create, list, update, delete for header and line-level per module) â€” backend/app/Http/Controllers/Api/V1/Admin/CustomFieldController.php
- [X] T129 [P] Implement `BackupController`: `POST /v1/admin/backup` (dispatches backup job), `GET /v1/admin/backup/download` (ZIP), `POST /v1/admin/restore` (upload + preview), `POST /v1/admin/restore/confirm` â€” backend/app/Http/Controllers/Api/V1/Admin/BackupController.php
- [X] T130 [P] Implement `BackupJob` (queued 300 s timeout): `mysqldump` via Symfony Process, archive uploads, create ZIP, upload to Google Drive via flysystem disk; on `failed()` hook log to `activity_log` and dispatch email alert to `company_settings.admin_alert_email` with failure reason â€” backend/app/Jobs/BackupJob.php
- [X] T131 [P] Implement Admin Flutter screens: company settings form, bank accounts list/form, users list/form (with role selector), numbering sequences, activity log viewer, custom fields manager â€” frontend/lib/features/admin/

### Ageing Reports (FR-023)

- [X] T140 [P] Implement `AgingReportService`: receivables ageing (outstanding `sales_invoices` grouped by customer, bucketed 0-30 / 31-60 / 61-90 / 90+ days overdue from invoice date) and payables ageing (outstanding `purchase_invoices` by vendor, same buckets); expose `GET /v1/reports/financial/receivables-aging` and `GET /v1/reports/financial/payables-aging` â€” backend/app/Services/AgingReportService.php + backend/app/Http/Controllers/Api/V1/Reports/FinancialReportController.php
- [X] T141 [P] Implement Receivables and Payables Ageing Flutter screens: tabbed view per bucket, drill-down to individual invoices, customer/vendor filter â€” frontend/lib/features/reports/screens/aging_report_screen.dart

### Document Template Builder (FR-027, FR-028)

- [X] T142 [P] Create `pdf_templates` migration and `PdfTemplate` Eloquent model (columns: `name`, `document_type` ENUM: sales_invoice/credit_note/quotation/purchase_order/delivery_challan, `logo_path`, `background_path`, `header_html` TEXT, `footer_html` TEXT, `field_visibility` JSON, `column_config` JSON, `is_default` BOOLEAN); allow multiple templates per `document_type` per tenant â€” backend/database/migrations/tenant/ + backend/app/Models/PdfTemplate.php
- [X] T143 [P] Implement `PdfTemplateController` (index, store, show, update, delete, `setDefault` action); extend `PdfService` to resolve the active template per document type and merge tenant data with template config before Blade render â€” backend/app/Http/Controllers/Api/V1/Admin/PdfTemplateController.php
- [X] T144 [P] Implement Template Builder Flutter screen: logo upload (file_picker), background image upload, header/footer HTML editor, field visibility toggle list per document type, column drag-to-reorder, save/set-as-default action â€” frontend/lib/features/admin/pdf_templates/

### Cross-Cutting Hardening

- [X] T132 [P] Add `ActivityLogObserver` Eloquent observer to all transactional models (log create/update/cancel with user and before/after values) â€” backend/app/Observers/
- [X] T133 [P] Configure rate limiting middleware: auth endpoints 10/min per IP, all others 120/min per token â€” backend/app/Providers/AppServiceProvider.php
- [X] T134 [P] Add `AccountingImbalanceException` handler: log to `activity_log`, send email to `company_settings.admin_alert_email` â€” backend/app/Exceptions/Handler.php
- [X] T135 [P] Create deployment guide: `.htaccess` setup, `cPanel` cron entry (`php artisan queue:work --stop-when-empty`), environment variables, storage symlink â€” backend/DEPLOY.md
- [X] T136 [P] Create Flutter build instructions: web build (`flutter build web`), Android APK, environment config per target â€” frontend/BUILD.md

**Checkpoint**: All modules functional. Admin can manage company, users, numbering, backups. Activity log captures all changes.

---

## Dependencies

```
Phase 1 â†’ Phase 2 â†’ Phase 3 (US1)
                  â†’ Phase 4 (US2) [can start in parallel with US1 after Foundation]
Phase 3 (US1) must complete before: Phase 5 (US3), Phase 7 (US5), Phase 10 (US8)
Phase 4 (US2) must complete before: Phase 6 (US4)
Phase 2 Foundation (Customer/Product APIs) required by: US1, US2, US3, US4, US5
US5 (GST Reports) depends on: US1, US2 (needs posted invoices with GST data)
US9 (Financial Reports) depends on: US1, US2, US3, US4 (needs ledger_entries populated)
Final Phase tasks are independent of each other â€” all parallelizable [P]
```

## Parallel Execution Per Story

| After Foundation completes... | Can run in parallel |
|-------------------------------|---------------------|
| US1 backend + US1 Flutter | T043â€“T049 â€– T050â€“T054 |
| US2 backend + US2 Flutter | T055â€“T059 â€– T060â€“T062 |
| US3 backend + US3 Flutter | T063â€“T066 â€– T067â€“T069 |
| US4 backend + US4 Flutter | T070â€“T073 â€– T074â€“T076 |
| US5 backend + US5 Flutter | T077â€“T079 â€– T080â€“T082, T139 |
| US6 backend + US6 Flutter | T083â€“T085 â€– T086â€“T088 |
| US7 backend + US7 Flutter | T089â€“T092, T137 â€– T093â€“T096, T138 |
| US8 backend + US8 Flutter | T097â€“T101 â€– T102â€“T104 |
| US9 backend + US9 Flutter | T105â€“T107 â€– T108â€“T112 |
| Final Phase | T113â€“T136, T140â€“T144 all [P] |

## Implementation Strategy

**MVP = Phase 1 + Phase 2 + Phase 3 (US1)**

This delivers end-to-end: tenant onboards â†’ admin creates customer and product â†’ billing operator creates and posts a GST-compliant sales invoice â†’ PDF downloads. All constitution principles satisfied from day one.

**Increment 2**: Add US2 (purchases) + US3 (receipts) + US4 (payments) â€” closes the payables/receivables loop.

**Increment 3**: Add US5 (GST reports) â€” delivers the compliance deliverable; system is now GST-filing ready.

**Increment 4**: Add US6, US7 (full master management + inventory) â€” production-grade master data quality.

**Increment 5**: Add US8, US9, Final Phase â€” completes the full feature set.

---

## Summary

| Metric | Count |
|--------|-------|
| Total tasks | 144 |
| Phase 1 (Setup) | 11 |
| Phase 2 (Foundation) | 31 |
| US1 â€” Sales Invoice | 12 |
| US2 â€” Purchase Invoice | 8 |
| US3 â€” Receipts | 7 |
| US4 â€” Payments | 7 |
| US5 â€” GST Reports | 7 |
| US6 â€” Master Management | 6 |
| US7 â€” Product/Inventory | 10 |
| US8 â€” Quotation/Conversion | 8 |
| US9 â€” Financial Reports | 8 |
| Final Phase (Polish) | 29 |
| Parallelizable tasks [P] | 99 |
| User-story-labeled tasks | 73 |

