<!--
SYNC IMPACT REPORT
==================
Version change: (none) → 1.0.0  (initial constitution, promoted from template)
Modified principles: N/A — all principles newly authored
Added sections:
  - Core Principles (7 principles)
  - Technology Stack Constraints
  - Development Workflow
  - Governance
Removed sections: N/A (template placeholders replaced)
Templates:
  - .specify/templates/plan-template.md  ✅ updated (Constitution Check gates added)
  - .specify/templates/spec-template.md  ✅ aligned, no changes required
  - .specify/templates/tasks-template.md ✅ aligned, no changes required
Follow-up TODOs: none — all placeholders resolved
-->

# Hexbase-Retail Constitution

## Core Principles

### I. API-First Architecture (NON-NEGOTIABLE)

The backend MUST be a pure Laravel REST API with no business logic or
state in the Flutter frontend. Every feature MUST expose its capabilities
through versioned API endpoints. The frontend consumes only these endpoints
and MUST NOT perform tax calculations, accounting entries, or validation
logic independently. This separation guarantees correctness across all
supported platforms (Android, iOS, Windows, web) without duplicating
rules.

### II. GST Compliance is Non-Negotiable (NON-NEGOTIABLE)

GST-critical database columns — including HSN/SAC, GST rate, CGST amount,
SGST amount, IGST amount, cess amount, place of supply, invoice type, and
ITC eligibility indicators — MUST remain fixed in the schema and MUST NOT
be removed, renamed, or made optional by any client configuration.
Tax calculations MUST be correct and reproducible from stored data at any
time. Compliance requirements take precedence over all customisation or
simplification requests. Any feature that risks tax accuracy MUST be
blocked until validated.

### III. Configuration-Driven Customisation (NON-NEGOTIABLE)

Client-specific variations such as additional header fields, custom
line-item columns, and document layouts MUST be implemented through
metadata/JSON configuration stored in definition tables — never through
code forks, separate branches, or per-client deployments. One codebase
MUST serve all clients. UI rendering MUST be metadata-driven. Any
request to hard-code a client-specific field into the shared schema
MUST be rejected unless it qualifies as GST-critical or universally
required.

### IV. Separate-Database Multi-Tenancy

Each client (tenant) MUST have their own isolated MySQL database. The
application MUST resolve the tenant database dynamically at runtime
using subdomain or tenant code. Tenant data MUST NOT be co-mingled
in shared tables. A single deployable application build MUST serve
all tenants. Per-tenant settings, feature flags, document templates,
and custom field definitions are stored within the tenant database.

### V. Double-Entry Accounting Integrity

Every financial transaction — sales invoice, purchase invoice, receipt,
payment, expense, stock adjustment, debit note, or credit note — MUST
automatically produce balanced double-entry ledger postings. No
transaction screen MUST allow saving without corresponding ledger
entries. The accounting engine MUST maintain: cash ledgers, bank ledgers,
sales ledger, purchase ledger, customer receivables, vendor payables,
tax ledgers, and expense ledgers. Trial balance, P&L, and balance sheet
MUST be derivable purely from posted ledger entries.

### VI. Security and Auditability

Role-based access control MUST be enforced at the API layer for every
endpoint — client-side permission checks alone are insufficient. Every
sensitive voucher MUST record `created_by`, `updated_by`, and timestamps
at minimum. Delete and cancel actions MUST be tracked and non-destructive
(soft delete or status change). Tenant data isolation MUST be enforced at
the database connection level. Auth endpoints MUST have rate limiting.
File uploads MUST be validated for type and size. API tokens MUST be
hashed and never logged in plaintext.

### VII. Data-Entry Speed — Keyboard-First UX

All data-entry forms MUST support full Tab navigation, Enter-as-Tab
behaviour (configurable), and Shift+Tab backward movement. Customer and
product fields MUST use search-first selection (type to search, not
scroll-to-select). Line-item grids MUST support keyboard entry and MUST
auto-create a new row when the operator tabs past the last column of
the current row. Frequent billing workflows MUST require the minimum
number of clicks. UX complexity MUST NOT be introduced if it slows
repeat-entry operators.

## Technology Stack Constraints

The following technology choices are fixed for this project and MUST NOT
be substituted without a constitution amendment:

- **Backend**: Laravel 11 REST API (PHP 8.2+), deployed on shared hosting
  via Composer; Docker used for development and CI only
- **Database**: MySQL 8.x; one database per tenant; migration-managed schema
- **Frontend**: Flutter (stable channel); Riverpod for state management;
  REST-only communication with the Laravel API
- **Authentication**: Laravel Sanctum token-based authentication
- **PDF Generation**: Queue-ready; MUST NOT block the main request cycle
- **Hosting target**: Shared hosting without Docker in production;
  single codebase deployment; configurable file storage per tenant

Third-party library additions require justification and MUST not
introduce GPL-incompatible licensing into the distribution.

## Development Workflow

- **Feature branches** MUST be created before any specification or
  implementation work begins (see `speckit.git.feature`)
- **Specs** MUST exist and be reviewed before planning begins
- **Plans** MUST pass the Constitution Check gate before Phase 0 research
- **Tasks** MUST reference user stories from `spec.md`; tasks without
  a user story reference are only permitted in Phase 1 (Setup) and
  Phase 2 (Foundation)
- **GST-critical changes** (tax fields, accounting engine, tenant
  resolution) MUST include an integration test covering the changed path
- **API changes** MUST preserve backward compatibility within a version;
  breaking changes require a version bump and a migration note
- **Database schema changes** MUST be delivered as Laravel migrations;
  direct `ALTER TABLE` in production is forbidden

## Governance

This constitution supersedes all other development practices and style
guides for Hexbase-Retail. Principles I, II, and III are non-negotiable
and cannot be waived for individual features without a MAJOR version
amendment to this document.

Amendment procedure:
1. Propose change with rationale, impact on existing features, and
   migration plan in a pull request updating this file
2. Review against existing GST compliance and multi-tenancy guarantees
3. Increment version per semantic versioning rules (see version line)
4. Update `plan-template.md` Constitution Check gates to reflect change
5. Commit with message: `docs: amend constitution to vX.Y.Z (<summary>)`

All feature plans MUST include a Constitution Check section verifying
compliance with principles I–VII before Phase 0 research begins.
See `.specify/templates/plan-template.md` for the gate checklist.

**Version**: 1.0.0 | **Ratified**: 2026-05-10 | **Last Amended**: 2026-05-10
