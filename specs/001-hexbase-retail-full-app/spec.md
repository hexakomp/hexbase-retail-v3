# Feature Specification: Hexbase-Retail — Small Shop GST Accounting System

**Feature Branch**: `001-hexbase-retail-full-app`  
**Created**: 2026-05-10  
**Status**: Draft  
**Input**: User description: "Build an application using the small-shop-gst-prd.md"

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Fast Sales Billing with GST (Priority: P1)

A billing operator opens a new sales invoice, selects a customer, adds line items by searching by product name or barcode, confirms quantities and rates, and saves a GST-compliant invoice with automatic tax calculation. The operator can print or download the PDF immediately after saving.

**Why this priority**: Sales invoicing is the highest-frequency daily workflow. Without correct, fast billing, the system has no core value. It is also the entry point for GST compliance (GSTR-1 data) and double-entry accounting.

**Independent Test**: Can be fully tested by: creating a customer, creating a product with HSN and GST rate, opening a new invoice, adding line items, saving, and verifying that CGST/SGST/IGST amounts are correctly computed and a downloadable PDF is produced.

**Acceptance Scenarios**:

1. **Given** a logged-in billing operator, **When** they create a sales invoice for a GST-registered B2B customer with two line items at 18% GST, **Then** the system computes CGST 9% and SGST 9% for intra-state or IGST 18% for inter-state, shows the tax breakup, and saves the invoice.
2. **Given** a saved sales invoice, **When** the operator clicks Print/Download, **Then** a correctly formatted PDF is generated with all GST-critical fields visible within an acceptable time.
3. **Given** an invoice with a discount on a line item, **When** the invoice is saved, **Then** the taxable value reflects the post-discount amount and the tax is calculated on the net taxable value.
4. **Given** a B2C customer (unregistered), **When** an invoice is created, **Then** the invoice type defaults to B2C and the GSTIN field is not mandatory.

---

### User Story 2 — Purchase Invoice Entry with ITC Tracking (Priority: P2)

An accountant enters a vendor purchase invoice by keying in vendor invoice details, line items, tax amounts, and marks ITC eligibility. The system stores the vendor's invoice reference for reconciliation and updates accounts payable.

**Why this priority**: Purchase entry drives ITC claims, payables management, and inventory updates — all critical for GST compliance and financial accuracy. This is the second most frequent daily workflow.

**Independent Test**: Can be fully tested by: selecting a vendor, entering a vendor invoice number, adding line items with GST breakup, marking ITC eligibility, saving, and verifying that payable balance updates and the ITC register shows the entry.

**Acceptance Scenarios**:

1. **Given** an accountant entering a purchase invoice with reverse charge applicable, **When** they mark the reverse charge indicator, **Then** the system records the transaction correctly and reflects it in the reverse charge register.
2. **Given** a purchase invoice with mixed ITC eligibility (some items eligible, some not), **When** the accountant marks eligibility per line, **Then** only eligible amounts appear in the ITC register.
3. **Given** a saved purchase invoice, **When** the accountant attaches a scanned PDF of the original vendor invoice, **Then** the attachment is stored and retrievable from the voucher record.
4. **Given** a purchase invoice linked to a purchase order, **When** the PO reference is selected, **Then** received quantities update the PO status to partial or complete.

---

### User Story 3 — Receipt and Payment Allocation (Priority: P3)

An accountant records money received from a customer, allocates the receipt against one or more outstanding sales invoices, and the system updates the customer's outstanding balance and the cash or bank ledger.

**Why this priority**: Receipts close the receivables loop and keep outstanding balances accurate. Without this, the system cannot produce correct ageing reports or customer statements.

**Independent Test**: Can be fully tested by: entering a receipt for a customer, allocating it against a specific invoice, and verifying the invoice outstanding balance drops to zero (or the correct partial amount) and the bank or cash ledger is updated.

**Acceptance Scenarios**:

1. **Given** a customer with two unpaid invoices, **When** a receipt is recorded and partially allocated to one invoice, **Then** the allocated invoice shows reduced outstanding and the other remains unchanged.
2. **Given** a receipt that exceeds all outstanding invoices, **When** it is recorded, **Then** the excess is stored as advance and shown on the customer ledger.
3. **Given** a UPI receipt, **When** the operator selects UPI as mode and enters a UPI reference, **Then** the reference is stored and appears in the bank statement view.

---

### User Story 4 — Vendor Payment Processing (Priority: P4)

An accountant records a payment to a vendor, allocates it against outstanding purchase invoices, and the system updates vendor payables and the bank or cash ledger.

**Why this priority**: Payment processing closes the payables loop and is symmetric with receipt handling. Required for accurate payables ageing and vendor ledger.

**Independent Test**: Can be fully tested by: entering a payment for a vendor, allocating against a purchase invoice, and verifying the payable balance decreases correctly.

**Acceptance Scenarios**:

1. **Given** a vendor with two outstanding purchase invoices, **When** a payment is recorded and allocated to both, **Then** both invoices show reduced outstanding and the bank ledger is updated.
2. **Given** an advance payment to a vendor before any invoice, **When** later a purchase invoice is received, **Then** the advance can be applied against the new invoice.

---

### User Story 5 — GST Report Generation (Priority: P5)

An accountant selects a date range and generates GSTR-1 classification summaries (B2B, B2C, HSN summary, document summary) and a GSTR-3B support summary for filing review.

**Why this priority**: GST reporting is the compliance deliverable. The business must file monthly/quarterly returns; incorrect summaries have legal consequences.

**Independent Test**: Can be fully tested by: posting several sales invoices of different types (B2B, B2C, export) in a period and verifying the GSTR-1 summary correctly categorises and totals each type.

**Acceptance Scenarios**:

1. **Given** a mix of B2B and B2C invoices in a month, **When** the GSTR-1 report is generated, **Then** B2B entries show customer GSTIN and invoice-level detail and B2C entries are aggregated correctly.
2. **Given** purchase invoices marked with ITC eligibility, **When** the ITC register is generated, **Then** only eligible purchase amounts appear in the summary.
3. **Given** invoices with multiple HSN codes, **When** the HSN summary report is generated, **Then** each HSN code shows aggregate taxable value, CGST, SGST, and IGST correctly summed.

---

### User Story 6 — Customer and Vendor Master Management (Priority: P6)

An administrator or accountant creates, edits, and searches customer and vendor records including GSTIN, address, credit terms, and opening balances.

**Why this priority**: Masters are a prerequisite for all transactional workflows. They must support search, GSTIN validation, and duplicate detection.

**Independent Test**: Can be fully tested by: creating a customer with GSTIN, editing their credit limit, searching by name or GSTIN, and verifying duplicate detection when the same GSTIN is entered twice.

**Acceptance Scenarios**:

1. **Given** a new customer with a GSTIN, **When** the same GSTIN is entered for a second customer, **Then** the system warns of a potential duplicate.
2. **Given** a customer record with an opening balance, **When** transactions are posted, **Then** the outstanding balance reflects the opening balance plus subsequent transactions.
3. **Given** a vendor search, **When** partial name is typed, **Then** matching vendors appear in a dropdown within an acceptable response time.

---

### User Story 7 — Product and Service Master with Inventory (Priority: P7)

An administrator creates product and service records with HSN/SAC codes, GST rates, and pricing. Inventory stock levels update automatically from purchase and sales transactions.

**Why this priority**: Product master drives GST classification on invoices. Inventory accuracy supports reorder alerts and stock valuation.

**Independent Test**: Can be fully tested by: creating a product with HSN code and GST rate, posting a purchase invoice and a sales invoice, and verifying stock levels update and the stock summary reflects the correct balance.

**Acceptance Scenarios**:

1. **Given** a product with a minimum stock level set, **When** stock falls below that level after a sales invoice, **Then** a reorder alert is triggered.
2. **Given** a service item with a SAC code, **When** added to a sales invoice, **Then** no inventory movement is created and the SAC code appears on the invoice.
3. **Given** a product with opening stock, **When** the stock summary is viewed, **Then** opening stock is included in the current balance.

---

### User Story 8 — Quotation to Invoice Conversion (Priority: P8)

A sales operator creates a quotation for a customer, sends it, and when accepted, converts it to a sales invoice with a single action — retaining all line items, addresses, and terms.

**Why this priority**: Quotations are a key pre-sales step. Conversion to invoice without re-entry eliminates errors and saves time for repeat transactions.

**Independent Test**: Can be fully tested by: creating a quotation, marking it accepted, converting it to invoice, and verifying all line items and customer details carry over correctly.

**Acceptance Scenarios**:

1. **Given** an accepted quotation, **When** it is converted to an invoice, **Then** all line items, HSN codes, rates, and addresses are pre-populated in the new invoice.
2. **Given** a quotation with a validity date that has passed, **When** a conversion is attempted, **Then** the system warns that the quotation has expired.

---

### User Story 9 — Financial Reports and Ledger Views (Priority: P9)

An accountant or shop owner views the day book, cash book, trial balance, profit and loss statement, and balance sheet for a selected date range or financial year.

**Why this priority**: Financial reports give owners visibility into profitability and cash position. They also serve as an audit trail.

**Independent Test**: Can be fully tested by: posting a few sales, purchase, and payment transactions and verifying trial balance debits equal credits and P&L shows the correct gross margin.

**Acceptance Scenarios**:

1. **Given** posted transactions, **When** the trial balance is generated, **Then** total debits equal total credits.
2. **Given** a date range, **When** the day book is opened, **Then** every voucher posted in that range appears in chronological order with voucher type, number, and amount.
3. **Given** a financial year, **When** the P&L report is generated, **Then** sales, purchases, and expense totals match the sum of posted vouchers for that year.

---

### User Story 10 — Per-Client Custom Fields and Document Templates (Priority: P10)

An administrator configures additional header fields (e.g., DC No, Vehicle No) and custom line-item columns (e.g., Batch, Weight) for a specific client without changing application code, and assigns a custom PDF template with the client's logo.

**Why this priority**: Client customisation without code changes is a key differentiator and supports the multi-tenant model. Without this, each client deployment requires code modifications.

**Independent Test**: Can be fully tested by: adding a custom header field definition, creating an invoice where that field appears, and verifying the field value appears on the printed PDF, while GST-critical columns remain unchanged.

**Acceptance Scenarios**:

1. **Given** a custom header field "DC No" defined for a client, **When** an invoice is created, **Then** "DC No" appears as an input field on screen and prints on the PDF if configured to show on print.
2. **Given** a custom line-item column "Batch No" defined for a client, **When** items are entered, **Then** "Batch No" is editable per line and does not replace or affect GST-critical columns.
3. **Given** a PDF template with an uploaded logo and custom layout, **When** an invoice PDF is generated, **Then** the logo and layout match the saved template.

---

### Edge Cases

- What happens when the same product appears twice on an invoice line? The system should allow duplicate product rows (different batches or rates) without merging them.
- What happens when a receipt is entered for an inactive customer? The system should warn and require confirmation or block the entry.
- What happens when GST rate on a product is changed after invoices have been posted? Previously posted invoices retain the original rate; new invoices use the updated rate.
- What happens when the financial year rolls over? Numbering sequences reset per configured financial year; vouchers from the old year remain accessible for reporting.
- What happens when two operators attempt to edit the same voucher simultaneously? Last-save-wins is acceptable at this scale; audit log records both attempts.
- What happens when a purchase invoice ITC eligibility is changed after initial entry? The change is logged in the audit trail and the ITC register reflects the updated status.
- What happens when a PDF template has no logo uploaded? The PDF generates without a logo placeholder error.

---

## Requirements *(mandatory)*

### Functional Requirements

**Authentication & Access**

- **FR-001**: The system MUST support login, logout, password reset, and token-based session management for all users.
- **FR-002**: The system MUST enforce role-based access control with at least four roles: Administrator, Accountant, Billing Operator, and View-Only.
- **FR-003**: Permissions MUST be configurable per module and per action (create, edit, delete, print, export, approve, view).

**Masters**

- **FR-004**: The system MUST maintain customer records with GSTIN, billing/shipping addresses, customer type, credit terms, and opening balance.
- **FR-005**: The system MUST maintain vendor records with GSTIN, payment terms, TDS applicability, and ITC notes.
- **FR-006**: The system MUST maintain product and service records with HSN/SAC codes, GST rate, cess rate, unit of measure, and pricing.
- **FR-007**: Customer and vendor search MUST support partial-name and GSTIN lookup with duplicate detection.

**Transactions**

- **FR-008**: The sales invoice MUST include all GST-critical fields: place of supply, invoice type (B2B/B2C/export/SEZ), HSN/SAC per line, CGST, SGST, IGST, cess, and taxable value.
- **FR-009**: The purchase invoice MUST record vendor invoice number, ITC eligibility per line, reverse charge indicator, and support attachment of the original invoice scan.
- **FR-010**: The system MUST support allocation of receipts against one or more sales invoices and handling of advance or excess amounts.
- **FR-011**: The system MUST support allocation of payments against one or more purchase invoices and advance payment handling.
- **FR-012**: Quotations MUST support conversion to sales invoice with all line items and customer details carried over.
- **FR-013**: Purchase orders MUST support linkage to purchase invoices with status tracking (open, partial, received, cancelled).
- **FR-013a**: The system MUST support a simple Delivery Challan (DC) module with its own number series, date, customer, billing/shipping address, and item rows (quantity, unit, description). DC documents MUST be printable as PDF. DCs produce no accounting or inventory postings in Phase 1; they are dispatch-tracking documents only.
- **FR-014**: Expenses MUST capture GST applicability, ITC eligibility, payment mode, and bank or cash account.

**Inventory**

- **FR-015**: Stock levels MUST update automatically from purchase and sales invoice postings.
- **FR-016**: The system MUST support manual stock adjustments and display reorder alerts when stock falls below minimum levels.

**Accounting Engine**

- **FR-017**: Every transaction MUST automatically produce balanced double-entry ledger postings without manual journal entry.
- **FR-018**: The system MUST maintain ledgers for cash, bank accounts, sales, purchases, customer receivables, vendor payables, tax, and expenses.

**GST Reporting**

- **FR-019**: The system MUST produce GSTR-1 classification summaries: B2B, B2C, HSN summary, document summary, and tax liability summary.
- **FR-020**: The system MUST produce a GSTR-3B support summary and an ITC register.
- **FR-021**: The system MUST maintain a sales tax register and a purchase tax register.

**Financial Reporting**

- **FR-022**: The system MUST provide a day book, sales register, purchase register, cash book, bank book, cash flow summary, trial balance, P&L statement, and balance sheet.
- **FR-023**: The system MUST provide receivables and payables ageing reports.

**Inventory Reporting**

- **FR-024**: The system MUST provide a stock summary, item ledger, low-stock report, and stock valuation summary.

**Debit Notes and Credit Notes**

- **FR-041**: The system MUST support credit notes (sales return / amendment) issued against sales invoices, with full GST-critical fields mirroring the original invoice structure.
- **FR-042**: The system MUST support debit notes issued against purchase invoices to record purchase returns or upward amendments.
- **FR-043**: Credit notes and debit notes MUST produce balanced double-entry ledger postings automatically and MUST appear in GSTR-1 amendment or document summary sections as required by Indian GST rules.

**PDF Generation**

- **FR-025**: The system MUST generate PDFs for sales invoices, credit notes, delivery challans, purchase orders, quotations, and all financial and GST reports using dompdf or tcpdf as the server-side rendering library.
- **FR-026**: Since the primary interface is web-based and direct browser printing is not reliable, PDF generation MUST produce a viewable PDF displayed in-browser (or downloadable) from which the user prints; this applies to both transactional documents and report exports. PDF generation MUST NOT block the main user interface.

**Document Templates**

- **FR-027**: The system MUST support a template builder allowing logo upload, background image upload, header/footer positioning, field visibility control, and column configuration.
- **FR-028**: Multiple templates MUST be saveable and assignable per document type.

**Customisation**

- **FR-029**: The system MUST support configurable additional header fields per module per client, stored as structured metadata — not as schema changes.
- **FR-030**: The system MUST support configurable line-item columns per client, stored separately from GST-critical fixed columns.
- **FR-031**: GST-critical columns MUST remain fixed and non-removable regardless of client configuration.

**Multi-Tenancy**

- **FR-032**: Each tenant MUST have an isolated database resolved dynamically at runtime by subdomain or tenant code.
- **FR-033**: One application codebase MUST serve all tenants without per-client deployments.

**Backup**

- **FR-034**: The system MUST support scheduled and manual backup of database, uploaded files, and templates to a configurable cloud storage destination.
- **FR-034a**: The system MUST allow an Administrator to download the current backup as a single ZIP file containing the database dump, uploaded files, and templates — without requiring server or command-line access.
- **FR-034b**: The system MUST provide a restore workflow that accepts an uploaded ZIP backup file and restores database and files from it, with a confirmation step before overwriting live data.
- **FR-035**: Backup and restore controls MUST be restricted to Administrator role.

**Audit**

- **FR-036**: Every sensitive voucher MUST record created-by, updated-by, and timestamps.
- **FR-037**: Delete and cancel actions MUST be non-destructive (soft delete or status change) and MUST be logged.

**Observability**

- **FR-044**: The system MUST maintain a database-backed application activity log (errors, warnings, critical events) viewable by the Administrator from the admin UI, showing event type, timestamp, affected module, and message.
- **FR-045**: The system MUST send an email alert to the configured administrator email address when a critical failure occurs — including backup failure, double-entry imbalance detection, and PDF generation error. The alert email address MUST be configurable per tenant.

**Usability**

- **FR-038**: All data-entry forms MUST support Tab navigation, configurable Enter-as-Tab, and Shift+Tab backward movement.
- **FR-039**: Customer and product fields MUST use search-first selection (type to search).
- **FR-040**: Line-item grids MUST auto-create a new row when the operator tabs past the last column of the current row.

### Key Entities

- **Tenant**: Isolated client instance; has its own database, settings, custom field definitions, and document templates.
- **User**: Has a role, belongs to a tenant, accesses modules per permission configuration.
- **Customer**: Trading party for sales; has GSTIN, addresses, type, credit terms, opening balance.
- **Vendor**: Trading party for purchases; has GSTIN, payment terms, TDS flag.
- **Product/Service**: Sellable item or service; has HSN/SAC, GST rate, pricing, stock tracking flag.
- **Sales Invoice**: Core outward supply document; has GST-critical fields, line items, double-entry postings.
- **Purchase Invoice**: Core inward supply document; has ITC eligibility, reverse charge flag, vendor reference, postings.
- **Receipt**: Money received from customer; allocated against invoices; updates receivables and cash/bank.
- **Payment**: Money paid to vendor; allocated against purchase invoices; updates payables and cash/bank.
- **Quotation**: Pre-sales document; convertible to sales invoice; has revision audit trail.
- **Purchase Order**: Pre-purchase document; linked to purchase invoice; tracks receipt status.
- **Delivery Challan**: Simple dispatch document; has own number series, customer, and item rows; printable as PDF; no accounting or inventory postings in Phase 1.
- **Expense**: Non-purchase expenditure; has GST, ITC eligibility, payment mode.
- **Ledger Entry**: Double-entry posting; always balanced; source of all financial reports.
- **Custom Field Definition**: Metadata defining client-specific header fields per module.
- **Line Column Definition**: Metadata defining client-specific line-item columns per module.
- **PDF Template**: Configurable document layout per document type per tenant.
- **Stock Movement**: Record of stock in/out from transactions; source of inventory reports.
- **Credit Note**: Document issued against a sales invoice to record returns or amendments; reduces customer receivable; reflected in GSTR-1 amendment data.
- **Debit Note**: Document issued against a purchase invoice to record purchase returns or upward amendments; reduces vendor payable.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A billing operator can create, save, and download a GST-compliant sales invoice with correct tax calculations in under 3 minutes for a typical 5-line-item invoice.
- **SC-002**: GSTR-1 classification summaries (B2B, B2C, HSN summary) can be generated for any completed month and are consistent with the individual posted invoices — zero discrepancy.
- **SC-003**: Trial balance debits equal credits at all times after any posted transaction — verified on demand without manual reconciliation.
- **SC-004**: A new tenant can be onboarded (database provisioned, company setup completed, first invoice raised) within one working day by an administrator without developer involvement.
- **SC-005**: Customer and product search returns results within 2 seconds on a shared hosting environment for a dataset of up to 10,000 records.
- **SC-006**: Adding or modifying a client-specific custom header field or line-item column requires no code change or redeployment — only configuration via the admin UI.
- **SC-007**: The system correctly handles intra-state (CGST+SGST) and inter-state (IGST) tax calculation for all invoice types (B2B, B2C, export, SEZ) with zero manual override required.
- **SC-008**: All five financial reports (day book, cash book, trial balance, P&L, balance sheet) reflect posted transactions accurately within one refresh cycle of posting.
- **SC-009**: A scheduled backup completes successfully and the restored data passes a functional smoke test (login, invoice creation, report generation) within the same session.
- **SC-010**: Role-based access control prevents a View-Only user from creating, editing, or deleting any voucher — verified without any workaround or API bypass.
- **SC-011**: A single document PDF (sales invoice, credit note, delivery challan, purchase order, or quotation) MUST be generated and available for in-browser display within 10 seconds on shared hosting infrastructure, with a loading indicator shown to the user during generation.

---

## Assumptions

- The application targets Indian businesses operating under GST; all tax rules follow Indian GST regulations (CGST/SGST for intra-state, IGST for inter-state).
- The initial deployment environment is shared hosting with PHP and MySQL; no Docker or container orchestration is available in production.
- Phase 1 covers all items listed in the PRD Phase 1 list; Phase 2 features (LLM extraction, WhatsApp/Telegram/email integrations, e-invoice, e-way bill) are out of scope for this specification.
- Offline form caching is not required for Phase 1; a stable internet connection is assumed for all users.
- The financial year follows the Indian April-to-March cycle; the system will support configurable financial year start month for edge cases.
- Multi-currency support is not required; all transactions are in Indian Rupees (INR).
- TDS (Tax Deducted at Source) on vendor payments is captured at the master level for reference but automated TDS calculation and filing is out of scope for Phase 1.
- E-invoice (IRN generation via IRP) and e-way bill integration are out of scope for Phase 1 but the data model must not preclude them.
- Bank reconciliation in Phase 1 is status-based (mark as reconciled); automated bank statement import is a Phase 2 enhancement.
- The system assumes a maximum of 10 concurrent users per tenant for Phase 1 sizing.
- No formal uptime SLA is defined; availability relies on the shared hosting provider. Disaster recovery is handled via ZIP backup download and ZIP-based restore from the admin UI.
- Stock valuation uses a simple average cost method unless the PRD specifies otherwise (it does not specify); this assumption is documented and can be overridden in Phase 2.

---

## Clarifications

### Session 2026-05-10

- Q: Should debit notes and credit notes be included as Phase 1 modules? → A: Yes, include both debit notes (against purchase invoices) and credit notes (against sales invoices) as Phase 1 modules.
- Q: What PDF generation library and display approach should be used? → A: Use dompdf or tcpdf for server-side PDF rendering. Since the primary interface is web-based and direct browser printing is unreliable, all documents (invoices, delivery challans, purchase orders, quotations) and reports (GST, financial) generate a PDF that is displayed in-browser or downloaded, from which the user prints.
- Q: What is the availability and recovery posture for the system? → A: Best-effort; no formal uptime SLA — rely on hosting provider availability. However, the system must support downloading a ZIP backup (database + files) directly from the admin UI, and must provide a ZIP-based restore workflow without requiring server or command-line access.
- Q: Should a Delivery Challan module be in Phase 1 scope? → A: Yes, include a simple DC module (own number series, date, customer, item rows, PDF print) with no accounting or inventory postings in Phase 1.
- Q: How should silent system failures (PDF error, backup failure, posting error) be surfaced? → A: Database-backed activity log in the admin UI showing recent errors + email alert to a configurable admin email address for critical failures (backup failure, double-entry imbalance, PDF error).
- Q: What is the acceptable PDF generation time for a single document? → A: Within 10 seconds for a single document (invoice, DC, PO, quotation) on shared hosting; a loading indicator is shown during generation.
