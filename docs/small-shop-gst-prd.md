# Small Shop GST Accounting System - Project Requirements Document

## Name of the Project 
Hexbase-Retail

## Document Overview

This document defines the functional and technical requirements for a small-shop GST accounting system intended for Indian businesses with approximately 2 to 10 users. The application is intended to support day-to-day accounting, billing, purchasing, inventory, GST compliance, reporting, and document generation while remaining simple enough to deploy on shared hosting infrastructure.

The system will be rebuilt from scratch using a Laravel REST API, MySQL database, and Flutter-based frontend to support cross-platform use across desktop, mobile, and web environments. Laravel is well suited for API-first development, authentication, background processing, and future integrations, while Flutter provides a consistent UI layer for fast form entry and multi-platform access.

## Project Goals

The primary goal is to provide a practical accounting and GST operations system for small shops that need faster billing, purchase entry, receivables tracking, payables tracking, expenses, inventory, and GST reporting without the complexity of large enterprise ERP systems.

The secondary goal is to support controlled client-level customization such as additional sales header fields, configurable invoice line columns, custom PDF layouts, and template-based document formats without requiring separate codebases for each client.

## Business Scope

The application shall support the following business functions:

- Customer management
- Vendor management
- Product and service management
- Quotations
- Purchase orders
- Sales invoices
- Receipts
- Purchase invoices
- Payments
- Simple inventory management
- Expense management
- GST reports
- Cash flow and bank tracking
- PDF generation for invoices, quotations, and purchase orders

The system shall align as closely as practical with common workflows used in Indian accounting products such as Tally, especially in data-entry style, document structure, GST-relevant fields, voucher-oriented navigation, and accounting outputs.

## Target Users

The intended users include:

- Shop owner
- Accountant
- Billing operator
- Sales staff
- Manager with reporting access

Typical installations are expected to have low user volume but high frequency of transactions and repeated form entry, which makes keyboard efficiency and data-entry speed essential requirements.

## Technology Stack

### Backend

- Laravel 11 as REST API framework
- Laravel Sanctum or equivalent token-based authentication for API access
- MySQL 8.x as transactional database
- Queue-ready architecture for future background tasks such as PDF generation, backups, notifications, and LLM extraction workflows

Laravel offers stronger ecosystem support than lighter PHP frameworks for API auth, model relationships, queues, and integrations, while still remaining deployable on modern shared hosting that supports Composer and current PHP versions.

### Frontend

- Flutter application for Android, iOS, Windows, and web
- REST-based communication with Laravel API
- State management using Riverpod 
- Offline-friendly form caching may be considered in later phases, but is not a mandatory phase-1 requirement

Flutter supports cross-platform form-heavy applications and clean separation from backend logic through API-driven design.

### Hosting

- Shared hosting as initial deployment target
- Single codebase deployment
- Client isolation via separate databases per tenant
- Configurable file storage for uploads, logos, and document backgrounds
- Will use Docker for development and testing, but deployment will be on shared hosting without Docker

## Multi-Client Architecture

The preferred client-isolation model is a common codebase with separate databases for each client. This approach reduces maintenance effort, simplifies bug fixes and updates, and still preserves data isolation per client compared with maintaining separate folders and codebases for every client.

Each tenant may be mapped by subdomain or tenant code. The application shall dynamically resolve tenant configuration and database connection at runtime. This architecture also supports per-client settings, document layouts, custom fields, and future feature flags without fragmenting the application code.

## Functional Requirements

### 1. Authentication and User Management

The system shall provide secure login, logout, password reset, and session/token management. It shall support role-based access control with at least the following roles:

- Administrator
- Accountant
- Billing operator
- View-only user

Permissions shall be configurable per module and per action such as create, edit, delete, print, export, approve, or view.

### 2. Company and Financial Setup

The system shall maintain company master data including:

- Company name
- Trade name
- GSTIN
- PAN
- Address
- State code
- Contact details
- Bank accounts
- Financial year settings
- Numbering rules for invoice, purchase order, receipt, quotations, payment, and other vouchers
- Default tax and rounding settings
- Logo and letterhead uploads

The system shall support financial-year-based numbering and reporting, especially for April-to-March accounting use typical in India.

### 3. Customer Management

Customer records shall include, where applicable:

- Customer code
- Legal name
- Trade name
- Contact person
- Mobile and WhatsApp number
- Email
- Billing address
- Shipping address
- State and state code
- Country
- GSTIN
- PAN
- Customer type such as regular, unregistered, composition, export, or consumer
- Credit limit
- Credit days
- Opening balance
- Price list or rate preference
- Notes
- Status

The system shall support customer search, filtering, duplicate detection, and outstanding balance display.

### 4. Vendor Management

Vendor records shall include fields similar to customers, with additional purchase-focused details such as:

- Vendor invoice preferences
- Default payment terms
- TDS applicability if required
- ITC-related notes

The system shall allow payable tracking and linkage with purchase transactions.

### 5. Product and Service Management

Product master shall support:

- Product code
- Barcode
- Product name
- Alternate name
- Product type such as goods or service
- Category and brand
- Description
- HSN or SAC code
- Unit of measure
- Purchase rate
- Selling rate
- MRP
- GST rate
- Cess rate if applicable
- Minimum stock level
- Opening stock quantity
- Opening stock value
- Status

The system shall allow both stock items and non-stock services. GST-relevant classification such as HSN or SAC and item tax rates are necessary for compliance-oriented invoicing and summaries.

### 6. Quotations

The quotation module shall support:

- Quotation number
- Date
- Customer
- Validity date
- Billing and shipping addresses
- Item rows
- Header and footer message like greeting, thanking notes etc 
- Terms and conditions
- Notes
- Status such as draft, sent, accepted, rejected, converted
- Conversion to sales invoice

The system shall maintain revision history or at minimum an audit trail for changed quotations.

### 7. Purchase Orders

The purchase order module shall support:

- PO number
- Date
- Vendor
- Delivery date
- Item rows
- Terms and conditions
- Status such as open, partial, received, cancelled
- Conversion or linkage to purchase invoice

### 8. Sales Invoice

The sales invoice module shall support fixed core fields including:

- Invoice number
- Invoice date
- Customer
- Billing and shipping addresses
- Place of supply
- Invoice type such as B2B, B2C, export, SEZ
- Payment terms
- Due date
- Item rows
- Tax breakup
- Round off
- Grand total
- Narration
- Status

The line-item structure shall include fixed GST-critical fields such as:

- Serial number
- Product or service
- HSN or SAC
- Quantity
- Unit
- Rate
- Discount
- Taxable value
- GST rate
- CGST amount
- SGST amount
- IGST amount
- Cess amount if applicable
- Line total

GST-relevant document data such as invoice type, place of supply, tax breakup, HSN summary support, and document numbering are required to produce GST-ready outputs and reports.

### 9. Purchase Invoice

The purchase module shall support:

- Purchase voucher number
- Vendor invoice number
- Vendor invoice date
- Entry date
- Vendor
- Item rows
- Tax breakup
- ITC eligibility indicator
- Reverse charge indicator if applicable
- Linked PO reference
- Narration
- Attachment of invoice scan or PDF
- Payment and outstanding status

Purchase capture shall retain vendor invoice references to support tax credit review, audit traceability, and future reconciliation workflows.

### 10. Receipts

The receipt module shall support money received from customers with:

- Receipt number
- Date
- Customer
- Amount
- Receipt mode such as cash, bank, UPI, cheque, NEFT, RTGS
- Bank account or cash ledger
- Reference number or cheque details
- Allocation against one or more invoices
- Excess or advance amount handling
- Narration

### 11. Payments

The payment module shall support money paid to vendors or others with:

- Payment number
- Date
- Payee
- Amount
- Mode
- Bank or cash account
- Reference details
- Allocation against purchase invoices
- Advance payment handling
- Narration

### 12. Inventory Management

Inventory shall be intentionally simple and suitable for small shops. It shall support:

- Item-wise stock ledger
- Stock in and stock out from purchases and sales
- Opening stock
- Manual stock adjustment
- Reorder level alerts
- Current stock valuation summary

The initial implementation may use a straightforward stock movement model instead of advanced warehouse logic.

### 13. Expense Management

The expense module shall support:

- Expense date
- Expense category
- Payee or vendor
- Amount
- GST applicability
- GST rate and tax amount where relevant
- ITC eligible or not
- Payment mode
- Bank or cash account
- Notes
- Attachment upload

Expenses shall be postable into accounting reports and cash or bank movement summaries.

## Configurable Fields and Layout Requirements

The system shall support controlled per-client customization without changing application code. This is especially important for sales and purchase documents where one client may require fields such as DC No, PO No, Reference No, Vehicle No, or LR No, while another client may not use them.

### Header-Level Custom Fields

The application shall support configurable additional header fields for modules such as sales invoice, quotation, purchase invoice, purchase order, receipt, and payment. These fields shall be defined in client configuration and stored as JSON or equivalent structured data against the transaction record.

Each custom field definition shall include:

- Module name
- Internal key
- Label
- Field type such as text, date, number, dropdown, checkbox
- Required flag
- Default value
- Show on screen flag
- Show on print or PDF flag
- Sort order
- Active status

### Line-Item Custom Columns

The system shall support configurable line-item columns per client. One client may use Description in the item grid, while another may use Size, Color, Batch, Serial No, or Weight. These custom row values shall be stored separately from the fixed GST-critical columns, preferably as structured JSON per line item with metadata-driven rendering.

Each line-column definition shall include:

- Column key
- Column label
- Input type
- Width or display size
- Required flag
- Show on screen flag
- Show on PDF flag
- Sort order
- Active status

GST-critical fields shall remain fixed and non-removable to preserve compliance and reporting consistency.

## Accounting Engine Requirements

The system shall maintain a double-entry accounting engine behind operational screens. Every transaction such as sale, purchase, receipt, payment, expense, stock adjustment, debit note, or credit note shall produce ledger entries automatically.

This engine shall support:

- Cash ledger
- Bank ledgers
- Sales ledger
- Purchase ledger
- Customer receivables
- Vendor payables
- Tax ledgers
- Expense ledgers
- Stock or inventory valuation accounts as needed

This requirement is essential to generate accurate trial balance, profit and loss statement, balance sheet, and cash or bank analysis.

## Reporting Requirements

### GST Reports

The system shall provide GST-oriented outputs including:

- GSTR-1 transaction classification support
- B2B summary
- B2C summary
- HSN summary
- Document summary
- Tax liability summary
- GSTR-3B support summary
- ITC register
- Sales tax register
- Purchase tax register

GST software for Indian businesses typically emphasizes tax-ready invoicing, classification of outward supplies, and reporting summaries required for return preparation.

### Financial Reports

The system shall provide:

- Day book
- Sales register
- Purchase register
- Receivables ageing
- Payables ageing
- Cash book
- Bank book
- Cash flow summary
- Trial balance
- Profit and loss statement
- Balance sheet
- Expense register

### Inventory Reports

The system shall provide:

- Stock summary
- Item ledger
- Low-stock report
- Purchase versus sales movement
- Stock valuation summary

## Bank and Cash Management

The system shall support:

- Multiple bank accounts
- Cash ledger
- Receipt and payment entries against selected accounts
- Bank-wise statement view
- Reconciliation status per bank transaction
- Cash and bank summary by date range

## PDF Generation and Template Builder

The application shall support document generation for invoices, quotations, and purchase orders as downloadable PDFs.

A template builder shall allow users to:

- Upload logo images
- Upload background images or letterpad artwork
- Position header, footer, and logo elements
- Control visibility of selected fields
- Configure table columns and widths
- Save multiple templates
- Assign templates by document type

The layout engine shall support per-client document appearance while reusing the same transactional data model. Template-driven invoice generation is a common requirement in configurable invoice systems and aligns with the need for variable document columns and visual formats.

## Usability Requirements

The system is expected to be form-heavy and used by operators who perform repeated entry. Therefore, speed and keyboard accessibility are core requirements.

### Keyboard Navigation

The application shall support:

- Tab navigation through all forms
- Optional Enter-as-Tab behavior in data-entry screens
- Shift+Tab backward movement
- Keyboard-friendly dropdown selection
- Keyboard save shortcuts where practical
- Fast navigation inside line-item grids
- Automatic new-row creation when item entry reaches end-of-row

### Form Design

- Responsive design across desktop and mobile
- Large touch-friendly controls on mobile while retaining keyboard speed on desktop
- Reduced clicks for frequent billing workflows
- Search-first field behavior for customer and product selection
- Inline validation and error hints
- Minimal modal usage during repeated billing entry

### List Screens

The application shall provide list pages with:

- Pagination
- Search and filter support
- Lazy loading or server-side pagination for performance
- Sort options
- Export options
- Row-level quick actions such as view, edit, print, cancel, duplicate

## Audit and Security Requirements

The system shall maintain audit data for critical changes including:

- Record created by
- Record updated by
- Timestamps
- Field-level or summary-level change log for sensitive vouchers
- Delete or cancel action tracking

Additional security requirements:

- Tenant data isolation
- Role-based access control
- Password hashing
- API token protection
- File upload validation
- Rate limiting for auth endpoints
- Backup and restore controls restricted to admins

## Backup and Restore

The application shall provide scheduled and manual backup capability with configurable cloud storage integration such as Google Drive or another supported cloud drive.

Backup scope shall include:

- Database dump
- Uploaded files
- Logos and background templates
- Optional application-level configuration export

Cloud-integrated backup is a strong operational requirement for small businesses that rely on shared hosting and need low-cost disaster recovery.

## Phase 2 Requirements

### LLM-Based Purchase Invoice Extraction

The application shall support upload of invoice images or PDFs and extraction of fields such as vendor name, invoice date, invoice number, GST amounts, item lines, and totals using LLM or vision APIs. The extracted data shall be presented in the purchase form for user review and approval before final save.

This phase shall remain approval-based, not fully automatic, to reduce risk in accounting data entry.

### Communication Integrations

The application shall support communication and reminder settings for:

- WhatsApp
- Telegram
- Email

Use cases shall include:

- Payment reminders
- Invoice sharing
- Statement sharing
- Due-date alerts
- Customer communication templates

## Non-Functional Requirements

### Performance

- Standard forms should load quickly on typical shared-hosting infrastructure
- Large list pages shall use server-side pagination
- Search endpoints shall be optimized with indexing
- PDF generation shall not block the main UI unnecessarily

### Scalability

The application is designed for small user counts but shall support moderate transaction growth per tenant. The chosen separate-database tenancy model allows scaling client data independently while preserving a single maintainable codebase.

### Maintainability

- Modular backend design by business domain
- API versioning strategy
- Centralized validation
- Config-driven field rendering
- Reusable reporting components
- Migration-based schema management

### Compliance and Reliability

The system shall preserve transaction auditability, numbering consistency, and tax data accuracy. GST-relevant summaries and invoice structures must remain stable even when clients enable custom business fields.

## Suggested Data Design Principles

The following principles shall guide implementation:

- Keep compliance-critical accounting and GST columns fixed in schema
- Store optional client-specific header fields as structured custom data
- Store optional line-column values as structured custom row data
- Maintain definition tables that drive field rendering, validation, and PDF visibility
- Keep one common codebase and separate tenant databases
- Use metadata-driven UI instead of hardcoded per-client forms

This pattern balances flexibility and maintainability better than creating different code branches or database structures for each customer.

## Suggested Implementation Phases

### Phase 1

1. Authentication and company setup
2. Customer, vendor, and product masters
3. Sales invoice with PDF
4. Receipts
5. Purchase invoice
6. Payments
7. Quotations and purchase orders
8. Inventory basics
9. Expense management
10. GST and financial reports
11. Backup integration
12. Configurable custom fields and columns

### Phase 2

1. LLM invoice extraction
2. WhatsApp, Telegram, and email integrations
3. Bank reconciliation improvements
4. Advanced dashboard and reminders
5. Optional e-invoice and e-way bill integration

## Deliverables Expected from Development

The project delivery should include:

- Source code for Laravel API
- Source code for Flutter frontend
- MySQL schema and migrations
- Tenant configuration model
- API documentation
- Test data or demo environment
- User manual or onboarding documentation
- Backup and restore guide
- Deployment guide for shared hosting

## Acceptance Criteria

The project shall be considered functionally acceptable when:

- Core masters and vouchers are operational
- Sales and purchase flows produce correct tax calculations
- Receipts and payments update outstanding balances correctly
- Inventory updates occur from transactional flows
- GST summaries can be generated from stored data
- PDF documents can be produced with configurable templates
- Tenant-specific custom fields and line columns work without code changes
- Role-based permissions and audit trails are functioning
- Backups can be executed and restored

## Final Recommendation

The recommended architecture is a Laravel REST API with Flutter frontend, MySQL storage, common codebase, and separate database per client. Fixed accounting and GST fields should remain part of the core schema, while variable business-specific fields should be handled through configuration-driven custom fields and configurable line-item columns. This gives the flexibility small businesses need without breaking reporting, tax compliance, or long-term maintainability.
