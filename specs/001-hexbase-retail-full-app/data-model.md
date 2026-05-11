# Data Model: Hexbase-Retail

**Branch**: `001-hexbase-retail-full-app` | **Date**: 2026-05-10  
**Source**: spec.md entities + research.md decisions

---

## Database Architecture

Two logical tiers:

1. **Central DB** (`hexbase_central`) — tenant registry only; shared across all instances
2. **Tenant DB** (`hexbase_<tenant_code>`) — all business data; one DB per tenant; schema identical across tenants

All models below live in the tenant DB unless marked **[CENTRAL]**.

---

## Central DB Tables

### `tenants` [CENTRAL]

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `name` | VARCHAR(150) | Client business name |
| `code` | VARCHAR(30) UNIQUE | Slug used for DB name and subdomain |
| `subdomain` | VARCHAR(80) UNIQUE | e.g. `shopname.hexbase.in` |
| `db_name` | VARCHAR(80) UNIQUE | e.g. `hexbase_shopname` |
| `db_host` | VARCHAR(120) | Default: configured in tenancy.php |
| `db_username` | VARCHAR(80) | |
| `db_password` | VARCHAR(255) | Encrypted at rest |
| `plan` | VARCHAR(30) | `standard` / `premium` |
| `active` | BOOLEAN DEFAULT true | |
| `created_at` / `updated_at` | TIMESTAMP | |

---

## Tenant DB Tables

### Authentication & Access

#### `users`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `name` | VARCHAR(150) | |
| `email` | VARCHAR(191) UNIQUE | |
| `password` | VARCHAR(255) | bcrypt hashed |
| `mobile` | VARCHAR(20) NULL | |
| `active` | BOOLEAN DEFAULT true | |
| `last_login_at` | TIMESTAMP NULL | |
| `created_at` / `updated_at` | TIMESTAMP | |
| `created_by` / `updated_by` | BIGINT NULL FK users | Audit |

> Roles and permissions managed by `spatie/laravel-permission` tables: `roles`, `permissions`, `model_has_roles`, `model_has_permissions`, `role_has_permissions`.

#### `personal_access_tokens` (Laravel Sanctum)

Standard Sanctum table; tokens hashed.

---

### Company Setup

#### `company_settings`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | Single row per tenant |
| `name` | VARCHAR(200) | Legal company name |
| `trade_name` | VARCHAR(200) NULL | |
| `gstin` | VARCHAR(15) NULL | 15-char GSTIN |
| `pan` | VARCHAR(10) NULL | |
| `address` | TEXT NULL | |
| `city` | VARCHAR(100) NULL | |
| `state` | VARCHAR(100) NULL | |
| `state_code` | CHAR(2) NULL | 2-digit GST state code |
| `pincode` | VARCHAR(10) NULL | |
| `country` | VARCHAR(60) DEFAULT 'India' | |
| `phone` | VARCHAR(20) NULL | |
| `email` | VARCHAR(191) NULL | |
| `website` | VARCHAR(255) NULL | |
| `logo_path` | VARCHAR(500) NULL | Storage path |
| `financial_year_start_month` | TINYINT DEFAULT 4 | April = 4 |
| `current_financial_year` | VARCHAR(9) NULL | e.g. `2025-2026` |
| `currency_symbol` | VARCHAR(5) DEFAULT '₹' | |
| `round_off_method` | ENUM('nearest', 'floor', 'ceil') DEFAULT 'nearest' | |
| `timezone` | VARCHAR(50) DEFAULT 'Asia/Kolkata' | |
| `admin_alert_email` | VARCHAR(191) NULL | For FR-044/FR-045 |
| `created_at` / `updated_at` | TIMESTAMP | |

#### `bank_accounts`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `name` | VARCHAR(150) | Display name e.g. "HDFC Current" |
| `bank_name` | VARCHAR(150) NULL | |
| `account_number` | VARCHAR(30) NULL | Encrypted |
| `ifsc` | VARCHAR(11) NULL | |
| `branch` | VARCHAR(150) NULL | |
| `opening_balance` | DECIMAL(15,2) DEFAULT 0 | |
| `active` | BOOLEAN DEFAULT true | |
| `created_at` / `updated_at` | TIMESTAMP | |

#### `numbering_sequences`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `module` | VARCHAR(50) | e.g. `sales_invoice`, `quotation`, `purchase_order`, `delivery_challan`, `receipt`, `payment`, `credit_note`, `debit_note` |
| `financial_year` | VARCHAR(9) | e.g. `2025-2026` |
| `prefix` | VARCHAR(20) NULL | e.g. `INV-` |
| `suffix` | VARCHAR(20) NULL | |
| `current_number` | INT DEFAULT 0 | Incremented atomically |
| `padding` | TINYINT DEFAULT 4 | Zero-pad length |
| `created_at` / `updated_at` | TIMESTAMP | |

**Unique**: `(module, financial_year)`

---

### Masters

#### `price_lists`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `name` | VARCHAR(150) | E.g. "Retail", "Wholesale", "Export" |
| `description` | TEXT NULL | |
| `active` | BOOLEAN DEFAULT true | |
| `created_at` / `updated_at` | TIMESTAMP | |

> Price list line items (product-specific overrides) are out of scope for Phase 1. This table provides the FK anchor for `customers.price_list_id`; Phase 2 will add `price_list_items` with per-product rate overrides.

---

#### `customers`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `code` | VARCHAR(30) UNIQUE NULL | Auto-generated or manual |
| `name` | VARCHAR(200) | Legal name |
| `trade_name` | VARCHAR(200) NULL | |
| `contact_person` | VARCHAR(150) NULL | |
| `mobile` | VARCHAR(20) NULL | |
| `whatsapp` | VARCHAR(20) NULL | |
| `email` | VARCHAR(191) NULL | |
| `billing_address` | TEXT NULL | |
| `billing_city` | VARCHAR(100) NULL | |
| `billing_state` | VARCHAR(100) NULL | |
| `billing_state_code` | CHAR(2) NULL | **GST-CRITICAL** |
| `billing_pincode` | VARCHAR(10) NULL | |
| `billing_country` | VARCHAR(60) DEFAULT 'India' | |
| `shipping_address` | TEXT NULL | |
| `shipping_city` | VARCHAR(100) NULL | |
| `shipping_state` | VARCHAR(100) NULL | |
| `shipping_state_code` | CHAR(2) NULL | |
| `shipping_pincode` | VARCHAR(10) NULL | |
| `gstin` | VARCHAR(15) NULL | **GST-CRITICAL** — validated format |
| `pan` | VARCHAR(10) NULL | |
| `customer_type` | ENUM('regular','unregistered','composition','export','consumer','sez') DEFAULT 'regular' | **GST-CRITICAL** |
| `credit_limit` | DECIMAL(15,2) DEFAULT 0 | |
| `credit_days` | SMALLINT DEFAULT 0 | |
| `opening_balance` | DECIMAL(15,2) DEFAULT 0 | |
| `opening_balance_type` | ENUM('debit','credit') DEFAULT 'debit' | |
| `price_list_id` | BIGINT NULL FK price_lists | |
| `notes` | TEXT NULL | |
| `active` | BOOLEAN DEFAULT true | |
| `created_at` / `updated_at` | TIMESTAMP | |
| `created_by` / `updated_by` | BIGINT NULL FK users | Audit |

**Index**: `gstin`, `name` (fulltext), `mobile`

#### `vendors`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `code` | VARCHAR(30) UNIQUE NULL | |
| `name` | VARCHAR(200) | |
| `trade_name` | VARCHAR(200) NULL | |
| `contact_person` | VARCHAR(150) NULL | |
| `mobile` | VARCHAR(20) NULL | |
| `email` | VARCHAR(191) NULL | |
| `billing_address` | TEXT NULL | |
| `billing_city` | VARCHAR(100) NULL | |
| `billing_state` | VARCHAR(100) NULL | |
| `billing_state_code` | CHAR(2) NULL | **GST-CRITICAL** |
| `billing_pincode` | VARCHAR(10) NULL | |
| `gstin` | VARCHAR(15) NULL | **GST-CRITICAL** |
| `pan` | VARCHAR(10) NULL | |
| `payment_terms_days` | SMALLINT DEFAULT 0 | |
| `tds_applicable` | BOOLEAN DEFAULT false | |
| `tds_rate` | DECIMAL(5,2) NULL | Reference only; no auto-calc Phase 1 |
| `itc_notes` | TEXT NULL | |
| `opening_balance` | DECIMAL(15,2) DEFAULT 0 | |
| `opening_balance_type` | ENUM('debit','credit') DEFAULT 'credit' | |
| `notes` | TEXT NULL | |
| `active` | BOOLEAN DEFAULT true | |
| `created_at` / `updated_at` | TIMESTAMP | |
| `created_by` / `updated_by` | BIGINT NULL FK users | Audit |

#### `products`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `code` | VARCHAR(30) UNIQUE NULL | |
| `barcode` | VARCHAR(50) NULL | |
| `name` | VARCHAR(200) | |
| `alternate_name` | VARCHAR(200) NULL | |
| `type` | ENUM('goods','service') DEFAULT 'goods' | |
| `category` | VARCHAR(100) NULL | |
| `brand` | VARCHAR(100) NULL | |
| `description` | TEXT NULL | |
| `hsn_sac` | VARCHAR(10) NULL | **GST-CRITICAL** — HSN for goods, SAC for services |
| `uom` | VARCHAR(20) DEFAULT 'NOS' | Unit of measure |
| `purchase_rate` | DECIMAL(15,4) DEFAULT 0 | |
| `selling_rate` | DECIMAL(15,4) DEFAULT 0 | |
| `mrp` | DECIMAL(15,4) NULL | |
| `gst_rate` | DECIMAL(5,2) DEFAULT 0 | **GST-CRITICAL** — e.g. 18.00 |
| `cess_rate` | DECIMAL(5,2) DEFAULT 0 | **GST-CRITICAL** — 0 if not applicable |
| `track_inventory` | BOOLEAN DEFAULT true | False for services |
| `min_stock_level` | DECIMAL(15,4) DEFAULT 0 | |
| `current_stock` | DECIMAL(15,4) DEFAULT 0 | Denormalized; maintained by trigger/service |
| `avg_cost` | DECIMAL(15,4) DEFAULT 0 | Weighted average cost (R-008) |
| `opening_stock_qty` | DECIMAL(15,4) DEFAULT 0 | |
| `opening_stock_value` | DECIMAL(15,2) DEFAULT 0 | |
| `active` | BOOLEAN DEFAULT true | |
| `created_at` / `updated_at` | TIMESTAMP | |
| `created_by` / `updated_by` | BIGINT NULL FK users | Audit |

**Index**: `hsn_sac`, `name` (fulltext), `barcode`

---

### Transactional Documents

#### `sales_invoices` — **GST-CRITICAL table**

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `invoice_number` | VARCHAR(50) UNIQUE | From numbering_sequences |
| `invoice_date` | DATE | |
| `customer_id` | BIGINT FK customers | |
| `billing_address_snapshot` | JSON | Address at time of invoice |
| `shipping_address_snapshot` | JSON | |
| `place_of_supply` | CHAR(2) | **GST-CRITICAL** — buyer's state code |
| `invoice_type` | ENUM('b2b','b2c','export','sez') | **GST-CRITICAL** |
| `payment_terms` | VARCHAR(50) NULL | e.g. `Net 30` |
| `due_date` | DATE NULL | |
| `narration` | TEXT NULL | |
| `taxable_total` | DECIMAL(15,2) DEFAULT 0 | Sum of line taxable values |
| `cgst_total` | DECIMAL(15,2) DEFAULT 0 | **GST-CRITICAL** |
| `sgst_total` | DECIMAL(15,2) DEFAULT 0 | **GST-CRITICAL** |
| `igst_total` | DECIMAL(15,2) DEFAULT 0 | **GST-CRITICAL** |
| `cess_total` | DECIMAL(15,2) DEFAULT 0 | **GST-CRITICAL** |
| `round_off` | DECIMAL(7,2) DEFAULT 0 | |
| `grand_total` | DECIMAL(15,2) DEFAULT 0 | |
| `outstanding_amount` | DECIMAL(15,2) DEFAULT 0 | Reduced by receipts |
| `status` | ENUM('draft','posted','cancelled') DEFAULT 'draft' | |
| `custom_fields` | JSON NULL | Client-specific header fields (FR-029) |
| `created_at` / `updated_at` | TIMESTAMP | |
| `created_by` / `updated_by` | BIGINT NULL FK users | Audit |
| `cancelled_at` / `cancelled_by` | TIMESTAMP / BIGINT NULL | Soft cancel |

#### `sales_invoice_lines` — **GST-CRITICAL table**

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `sales_invoice_id` | BIGINT FK sales_invoices | |
| `serial_number` | SMALLINT | Line order |
| `product_id` | BIGINT FK products | |
| `description` | VARCHAR(500) NULL | Overrideable |
| `hsn_sac` | VARCHAR(10) | **GST-CRITICAL** — snapshot from product |
| `quantity` | DECIMAL(15,4) | |
| `uom` | VARCHAR(20) | |
| `rate` | DECIMAL(15,4) | |
| `discount_percent` | DECIMAL(5,2) DEFAULT 0 | |
| `discount_amount` | DECIMAL(15,2) DEFAULT 0 | |
| `taxable_value` | DECIMAL(15,2) | **GST-CRITICAL** = (qty × rate) − discount |
| `gst_rate` | DECIMAL(5,2) | **GST-CRITICAL** |
| `cgst_rate` | DECIMAL(5,2) DEFAULT 0 | **GST-CRITICAL** |
| `sgst_rate` | DECIMAL(5,2) DEFAULT 0 | **GST-CRITICAL** |
| `igst_rate` | DECIMAL(5,2) DEFAULT 0 | **GST-CRITICAL** |
| `cgst_amount` | DECIMAL(15,2) DEFAULT 0 | **GST-CRITICAL** |
| `sgst_amount` | DECIMAL(15,2) DEFAULT 0 | **GST-CRITICAL** |
| `igst_amount` | DECIMAL(15,2) DEFAULT 0 | **GST-CRITICAL** |
| `cess_rate` | DECIMAL(5,2) DEFAULT 0 | **GST-CRITICAL** |
| `cess_amount` | DECIMAL(15,2) DEFAULT 0 | **GST-CRITICAL** |
| `line_total` | DECIMAL(15,2) | |
| `custom_columns` | JSON NULL | Client-specific line columns (FR-030) |

#### `purchase_invoices` — **GST-CRITICAL table**

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `voucher_number` | VARCHAR(50) UNIQUE | Internal number |
| `vendor_invoice_number` | VARCHAR(100) NULL | As on vendor's document |
| `vendor_invoice_date` | DATE NULL | |
| `entry_date` | DATE | |
| `vendor_id` | BIGINT FK vendors | |
| `purchase_order_id` | BIGINT NULL FK purchase_orders | Linked PO |
| `reverse_charge` | BOOLEAN DEFAULT false | **GST-CRITICAL** |
| `narration` | TEXT NULL | |
| `taxable_total` | DECIMAL(15,2) DEFAULT 0 | |
| `cgst_total` | DECIMAL(15,2) DEFAULT 0 | **GST-CRITICAL** |
| `sgst_total` | DECIMAL(15,2) DEFAULT 0 | **GST-CRITICAL** |
| `igst_total` | DECIMAL(15,2) DEFAULT 0 | **GST-CRITICAL** |
| `cess_total` | DECIMAL(15,2) DEFAULT 0 | **GST-CRITICAL** |
| `round_off` | DECIMAL(7,2) DEFAULT 0 | |
| `grand_total` | DECIMAL(15,2) DEFAULT 0 | |
| `outstanding_amount` | DECIMAL(15,2) DEFAULT 0 | |
| `attachment_path` | VARCHAR(500) NULL | Scanned vendor invoice |
| `status` | ENUM('draft','posted','cancelled') DEFAULT 'draft' | |
| `custom_fields` | JSON NULL | |
| `created_at` / `updated_at` | TIMESTAMP | |
| `created_by` / `updated_by` | BIGINT NULL FK users | |
| `cancelled_at` / `cancelled_by` | TIMESTAMP / BIGINT NULL | |

#### `purchase_invoice_lines` — **GST-CRITICAL table**

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `purchase_invoice_id` | BIGINT FK purchase_invoices | |
| `serial_number` | SMALLINT | |
| `product_id` | BIGINT FK products | |
| `description` | VARCHAR(500) NULL | |
| `hsn_sac` | VARCHAR(10) | **GST-CRITICAL** |
| `quantity` | DECIMAL(15,4) | |
| `uom` | VARCHAR(20) | |
| `rate` | DECIMAL(15,4) | |
| `discount_amount` | DECIMAL(15,2) DEFAULT 0 | |
| `taxable_value` | DECIMAL(15,2) | **GST-CRITICAL** |
| `gst_rate` | DECIMAL(5,2) | **GST-CRITICAL** |
| `cgst_rate` | DECIMAL(5,2) DEFAULT 0 | **GST-CRITICAL** |
| `sgst_rate` | DECIMAL(5,2) DEFAULT 0 | **GST-CRITICAL** |
| `igst_rate` | DECIMAL(5,2) DEFAULT 0 | **GST-CRITICAL** |
| `cgst_amount` | DECIMAL(15,2) DEFAULT 0 | **GST-CRITICAL** |
| `sgst_amount` | DECIMAL(15,2) DEFAULT 0 | **GST-CRITICAL** |
| `igst_amount` | DECIMAL(15,2) DEFAULT 0 | **GST-CRITICAL** |
| `cess_amount` | DECIMAL(15,2) DEFAULT 0 | **GST-CRITICAL** |
| `itc_eligible` | BOOLEAN DEFAULT true | **GST-CRITICAL** |
| `line_total` | DECIMAL(15,2) | |
| `custom_columns` | JSON NULL | |

#### `receipts`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `receipt_number` | VARCHAR(50) UNIQUE | |
| `receipt_date` | DATE | |
| `customer_id` | BIGINT FK customers | |
| `amount` | DECIMAL(15,2) | Total receipt amount |
| `mode` | ENUM('cash','bank','upi','cheque','neft','rtgs','other') | |
| `bank_account_id` | BIGINT NULL FK bank_accounts | Null for cash |
| `reference_number` | VARCHAR(100) NULL | Cheque/UTR/UPI ref |
| `reference_date` | DATE NULL | |
| `advance_amount` | DECIMAL(15,2) DEFAULT 0 | Unapplied excess |
| `narration` | TEXT NULL | |
| `status` | ENUM('draft','posted','cancelled') DEFAULT 'draft' | |
| `custom_fields` | JSON NULL | |
| `created_at` / `updated_at` | TIMESTAMP | |
| `created_by` / `updated_by` | BIGINT NULL FK users | |

#### `receipt_allocations`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `receipt_id` | BIGINT FK receipts | |
| `sales_invoice_id` | BIGINT FK sales_invoices | |
| `allocated_amount` | DECIMAL(15,2) | |
| `created_at` | TIMESTAMP | |

#### `payments`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `payment_number` | VARCHAR(50) UNIQUE | |
| `payment_date` | DATE | |
| `vendor_id` | BIGINT FK vendors | |
| `amount` | DECIMAL(15,2) | |
| `mode` | ENUM('cash','bank','upi','cheque','neft','rtgs','other') | |
| `bank_account_id` | BIGINT NULL FK bank_accounts | |
| `reference_number` | VARCHAR(100) NULL | |
| `reference_date` | DATE NULL | |
| `advance_amount` | DECIMAL(15,2) DEFAULT 0 | |
| `narration` | TEXT NULL | |
| `status` | ENUM('draft','posted','cancelled') DEFAULT 'draft' | |
| `custom_fields` | JSON NULL | |
| `created_at` / `updated_at` | TIMESTAMP | |
| `created_by` / `updated_by` | BIGINT NULL FK users | |

#### `payment_allocations`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `payment_id` | BIGINT FK payments | |
| `purchase_invoice_id` | BIGINT FK purchase_invoices | |
| `allocated_amount` | DECIMAL(15,2) | |
| `created_at` | TIMESTAMP | |

#### `quotations`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `quotation_number` | VARCHAR(50) UNIQUE | |
| `quotation_date` | DATE | |
| `validity_date` | DATE NULL | |
| `customer_id` | BIGINT FK customers | |
| `billing_address_snapshot` | JSON NULL | |
| `shipping_address_snapshot` | JSON NULL | |
| `terms_conditions` | TEXT NULL | |
| `header_message` | TEXT NULL | |
| `footer_message` | TEXT NULL | |
| `taxable_total` | DECIMAL(15,2) DEFAULT 0 | |
| `tax_total` | DECIMAL(15,2) DEFAULT 0 | |
| `grand_total` | DECIMAL(15,2) DEFAULT 0 | |
| `status` | ENUM('draft','sent','accepted','rejected','converted','expired') DEFAULT 'draft' | |
| `converted_invoice_id` | BIGINT NULL FK sales_invoices | |
| `custom_fields` | JSON NULL | |
| `created_at` / `updated_at` | TIMESTAMP | |
| `created_by` / `updated_by` | BIGINT NULL FK users | |

#### `quotation_lines`

Mirrors `sales_invoice_lines` structure with same GST-critical columns; FK to `quotations`.

#### `purchase_orders`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `po_number` | VARCHAR(50) UNIQUE | |
| `po_date` | DATE | |
| `delivery_date` | DATE NULL | |
| `vendor_id` | BIGINT FK vendors | |
| `terms_conditions` | TEXT NULL | |
| `grand_total` | DECIMAL(15,2) DEFAULT 0 | |
| `status` | ENUM('open','partial','received','cancelled') DEFAULT 'open' | |
| `custom_fields` | JSON NULL | |
| `created_at` / `updated_at` | TIMESTAMP | |
| `created_by` / `updated_by` | BIGINT NULL FK users | |

#### `purchase_order_lines`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `purchase_order_id` | BIGINT FK purchase_orders | |
| `serial_number` | SMALLINT | |
| `product_id` | BIGINT FK products | |
| `description` | VARCHAR(500) NULL | |
| `quantity` | DECIMAL(15,4) | |
| `received_quantity` | DECIMAL(15,4) DEFAULT 0 | Updated on PO link |
| `uom` | VARCHAR(20) | |
| `rate` | DECIMAL(15,4) | |
| `line_total` | DECIMAL(15,2) | |

#### `delivery_challans`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `dc_number` | VARCHAR(50) UNIQUE | Own number series |
| `dc_date` | DATE | |
| `customer_id` | BIGINT FK customers | |
| `billing_address_snapshot` | JSON NULL | |
| `shipping_address_snapshot` | JSON NULL | |
| `narration` | TEXT NULL | |
| `status` | ENUM('draft','dispatched','cancelled') DEFAULT 'draft' | |
| `custom_fields` | JSON NULL | |
| `created_at` / `updated_at` | TIMESTAMP | |
| `created_by` / `updated_by` | BIGINT NULL FK users | |
| No accounting or inventory postings in Phase 1 | — | Per FR-013a |

#### `delivery_challan_lines`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `delivery_challan_id` | BIGINT FK delivery_challans | |
| `serial_number` | SMALLINT | |
| `product_id` | BIGINT NULL FK products | |
| `description` | VARCHAR(500) NULL | |
| `quantity` | DECIMAL(15,4) | |
| `uom` | VARCHAR(20) NULL | |
| `custom_columns` | JSON NULL | |

#### `credit_notes` — **GST-CRITICAL table** (FR-041)

Mirrors `sales_invoices` + `sales_invoice_lines` structure. Additional columns:

| Column | Type | Notes |
|--------|------|-------|
| `original_invoice_id` | BIGINT NULL FK sales_invoices | Source invoice |
| `reason` | VARCHAR(255) NULL | Return, amendment, etc. |

#### `debit_notes` — **GST-CRITICAL table** (FR-042)

Mirrors `purchase_invoices` + `purchase_invoice_lines` structure. Additional columns:

| Column | Type | Notes |
|--------|------|-------|
| `original_purchase_invoice_id` | BIGINT NULL FK purchase_invoices | |
| `reason` | VARCHAR(255) NULL | |

#### `expenses`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `expense_date` | DATE | |
| `category` | VARCHAR(100) | |
| `vendor_id` | BIGINT NULL FK vendors | |
| `payee_name` | VARCHAR(150) NULL | If not a registered vendor |
| `amount` | DECIMAL(15,2) | |
| `gst_applicable` | BOOLEAN DEFAULT false | |
| `gst_rate` | DECIMAL(5,2) DEFAULT 0 | **GST-CRITICAL if applicable** |
| `cgst_amount` | DECIMAL(15,2) DEFAULT 0 | **GST-CRITICAL** |
| `sgst_amount` | DECIMAL(15,2) DEFAULT 0 | **GST-CRITICAL** |
| `igst_amount` | DECIMAL(15,2) DEFAULT 0 | **GST-CRITICAL** |
| `itc_eligible` | BOOLEAN DEFAULT false | **GST-CRITICAL** |
| `mode` | ENUM('cash','bank','upi','cheque','neft','rtgs','other') | |
| `bank_account_id` | BIGINT NULL FK bank_accounts | |
| `notes` | TEXT NULL | |
| `attachment_path` | VARCHAR(500) NULL | |
| `status` | ENUM('draft','posted','cancelled') DEFAULT 'draft' | |
| `created_at` / `updated_at` | TIMESTAMP | |
| `created_by` / `updated_by` | BIGINT NULL FK users | |

---

### Accounting Engine

#### `ledger_accounts`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `name` | VARCHAR(150) | e.g. "Cash", "HDFC Bank", "Sales", "CGST Payable" |
| `type` | ENUM('asset','liability','equity','income','expense') | |
| `sub_type` | VARCHAR(50) NULL | e.g. `bank`, `receivable`, `tax`, `stock` |
| `code` | VARCHAR(30) NULL | Chart of accounts code |
| `system_account` | BOOLEAN DEFAULT false | Seeded accounts; cannot be deleted |
| `bank_account_id` | BIGINT NULL FK bank_accounts | For bank-type ledgers |
| `active` | BOOLEAN DEFAULT true | |
| `created_at` / `updated_at` | TIMESTAMP | |

#### `ledger_entries`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `ledger_account_id` | BIGINT FK ledger_accounts | |
| `source_type` | VARCHAR(50) | Morph type: `sales_invoice`, `payment`, etc. |
| `source_id` | BIGINT | Morph ID |
| `entry_date` | DATE | |
| `debit` | DECIMAL(15,2) DEFAULT 0 | |
| `credit` | DECIMAL(15,2) DEFAULT 0 | |
| `narration` | VARCHAR(500) NULL | |
| `created_at` | TIMESTAMP | |
| `created_by` | BIGINT NULL FK users | |

**Index**: `(source_type, source_id)`, `(ledger_account_id, entry_date)`

> **Invariant**: For every `source_type + source_id`, `SUM(debit) = SUM(credit)`. Enforced in `AccountingEngine::post()` before commit.

---

### Inventory

#### `stock_movements`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `product_id` | BIGINT FK products | |
| `movement_type` | ENUM('purchase','sale','adjustment','opening') | |
| `source_type` | VARCHAR(50) | Morph: `purchase_invoice`, `sales_invoice`, etc. |
| `source_id` | BIGINT | |
| `quantity_in` | DECIMAL(15,4) DEFAULT 0 | |
| `quantity_out` | DECIMAL(15,4) DEFAULT 0 | |
| `rate` | DECIMAL(15,4) DEFAULT 0 | Unit cost at movement time |
| `movement_date` | DATE | |
| `created_at` | TIMESTAMP | |

---

### Customisation

#### `custom_field_definitions`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `module` | VARCHAR(50) | e.g. `sales_invoice`, `receipt` |
| `key` | VARCHAR(60) | Internal key; no spaces |
| `label` | VARCHAR(100) | Display label |
| `field_type` | ENUM('text','date','number','dropdown','checkbox') | |
| `required` | BOOLEAN DEFAULT false | |
| `default_value` | VARCHAR(255) NULL | |
| `show_on_screen` | BOOLEAN DEFAULT true | |
| `show_on_pdf` | BOOLEAN DEFAULT false | |
| `sort_order` | SMALLINT DEFAULT 0 | |
| `active` | BOOLEAN DEFAULT true | |
| `dropdown_options` | JSON NULL | For dropdown type |
| `created_at` / `updated_at` | TIMESTAMP | |

**Unique**: `(module, key)`

#### `line_column_definitions`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `module` | VARCHAR(50) | e.g. `sales_invoice` |
| `key` | VARCHAR(60) | |
| `label` | VARCHAR(100) | |
| `input_type` | ENUM('text','number','date','dropdown') | |
| `width` | VARCHAR(20) NULL | CSS width hint |
| `required` | BOOLEAN DEFAULT false | |
| `show_on_screen` | BOOLEAN DEFAULT true | |
| `show_on_pdf` | BOOLEAN DEFAULT false | |
| `sort_order` | SMALLINT DEFAULT 0 | |
| `active` | BOOLEAN DEFAULT true | |
| `created_at` / `updated_at` | TIMESTAMP | |

**Unique**: `(module, key)`

---

### PDF Templates

#### `pdf_templates`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `name` | VARCHAR(100) | |
| `document_type` | VARCHAR(50) | e.g. `sales_invoice`, `quotation` |
| `is_default` | BOOLEAN DEFAULT false | |
| `logo_path` | VARCHAR(500) NULL | |
| `background_path` | VARCHAR(500) NULL | |
| `layout_config` | JSON | Header/footer positions, field visibility, column widths |
| `created_at` / `updated_at` | TIMESTAMP | |

---

### Observability & Backup

#### `activity_logs`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `level` | ENUM('info','warning','error','critical') | |
| `module` | VARCHAR(60) NULL | |
| `message` | TEXT | |
| `context` | JSON NULL | Additional data |
| `user_id` | BIGINT NULL FK users | |
| `created_at` | TIMESTAMP | |

**Index**: `(level, created_at)`

#### `backups`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | |
| `type` | ENUM('scheduled','manual') | |
| `status` | ENUM('pending','running','completed','failed') | |
| `file_path` | VARCHAR(500) NULL | Local path before upload |
| `cloud_path` | VARCHAR(500) NULL | Remote path on Drive |
| `file_size_bytes` | BIGINT NULL | |
| `started_at` / `completed_at` | TIMESTAMP NULL | |
| `error_message` | TEXT NULL | |
| `created_at` | TIMESTAMP | |
| `created_by` | BIGINT NULL FK users | |

---

## Validation Rules

| Entity | Rule |
|--------|------|
| `customers.gstin` | 15-char regex: `^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$` or NULL |
| `vendors.gstin` | Same regex or NULL |
| `sales_invoices` | `SUM(cgst+sgst+igst) = tax_total`; `taxable_total + tax_total + cess_total + round_off = grand_total` |
| `ledger_entries` per source | `SUM(debit) = SUM(credit)` — enforced in AccountingEngine |
| `numbering_sequences` | Current number incremented atomically with DB-level lock |
| `products.gst_rate` | Must be one of: 0, 0.1, 0.25, 1, 1.5, 3, 5, 6, 7.5, 9, 12, 14, 18, 28 |

---

## State Transitions

### Sales Invoice
`draft` → `posted` (triggers ledger entries + stock movements) → `cancelled` (soft; reversal entries posted)

### Purchase Invoice
`draft` → `posted` → `cancelled`

### Quotation
`draft` → `sent` → `accepted` | `rejected` | `expired` → `converted` (creates sales invoice)

### Purchase Order
`open` → `partial` (on first linked purchase invoice) → `received` (on full receipt) | `cancelled`

### Receipt / Payment
`draft` → `posted` → `cancelled`

### Delivery Challan
`draft` → `dispatched` → `cancelled`

---

## Entity Relationship Summary

```
tenants [CENTRAL]
  └── users, company_settings, bank_accounts, numbering_sequences [per tenant DB]

customers ──< sales_invoices ──< sales_invoice_lines
                    │
                    ├──< receipt_allocations >── receipts ──> bank_accounts
                    └──> credit_notes ──< credit_note_lines

vendors ──< purchase_invoices ──< purchase_invoice_lines
                    │
                    ├──< payment_allocations >── payments ──> bank_accounts
                    ├──> debit_notes ──< debit_note_lines
                    └──> purchase_orders ──< purchase_order_lines

customers ──< quotations ──< quotation_lines ──> [converted_invoice_id] sales_invoices
customers ──< delivery_challans ──< delivery_challan_lines

products ──< stock_movements
products ──< sales_invoice_lines
products ──< purchase_invoice_lines

ledger_accounts ──< ledger_entries [morphed to all transaction sources]

custom_field_definitions [per module]
line_column_definitions [per module]
pdf_templates [per document_type]
activity_logs
backups
```
