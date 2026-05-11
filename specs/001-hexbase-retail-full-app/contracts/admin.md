# API Contract: Admin (Company, Templates, Custom Fields, Backup, Tenants, Activity Log)

**Base**: `/api/v1`  
**Auth**: Required  
**Most endpoints**: admin role only

---

## Company Settings

### GET /admin/company

Get company settings.  
**Roles**: admin, acc, view

### PUT /admin/company

Update company settings.  
**Roles**: admin

**Request**:
```json
{
  "name": "Sharma General Stores",
  "gstin": "29XXXXX1234X1ZY",
  "pan": "XXXXX1234X",
  "address": "45 Market Street",
  "city": "Hubli",
  "state": "Karnataka",
  "state_code": "29",
  "pincode": "580028",
  "phone": "0836-2200001",
  "email": "accounts@sharma.in",
  "financial_year_start_month": 4,
  "round_off_method": "nearest",
  "admin_alert_email": "owner@sharma.in"
}
```

### POST /admin/company/logo

Upload company logo.  
**Content-Type**: multipart/form-data — `logo` (PNG/JPG, max 2MB)  
**Roles**: admin

---

## Bank Accounts

### GET /admin/bank-accounts
### POST /admin/bank-accounts
### PUT /admin/bank-accounts/{id}
### DELETE /admin/bank-accounts/{id}

**Roles**: admin

---

## Numbering Sequences

### GET /admin/numbering-sequences

List all sequences for current financial year.

### PUT /admin/numbering-sequences/{id}

Update prefix, suffix, padding. Cannot decrease `current_number`.  
**Roles**: admin

---

## PDF Templates

### GET /admin/pdf-templates

List templates by document type.  
**Roles**: admin, acc, view

### POST /admin/pdf-templates

**Roles**: admin  
**Request**:
```json
{
  "name": "Standard Invoice Template",
  "document_type": "sales_invoice",
  "is_default": true,
  "layout_config": {
    "show_logo": true,
    "logo_position": "top-left",
    "show_background": false,
    "header_fields": ["company_name", "gstin", "address"],
    "visible_columns": ["serial", "description", "hsn", "qty", "rate", "taxable", "gst", "total"],
    "footer_text": "Thank you for your business!"
  }
}
```

### PUT /admin/pdf-templates/{id}
### DELETE /admin/pdf-templates/{id}
### POST /admin/pdf-templates/{id}/logo

Upload template logo. **Content-Type**: multipart/form-data

### POST /admin/pdf-templates/{id}/background

Upload background image. **Content-Type**: multipart/form-data

---

## Custom Field Definitions

### GET /admin/custom-fields

**Query**: `module`  
**Roles**: admin

### POST /admin/custom-fields

**Roles**: admin  
**Request**:
```json
{
  "module": "sales_invoice",
  "key": "dc_no",
  "label": "DC Number",
  "field_type": "text",
  "required": false,
  "show_on_screen": true,
  "show_on_pdf": true,
  "sort_order": 1
}
```

**Response 409**: Key already exists for this module

### PUT /admin/custom-fields/{id}
### DELETE /admin/custom-fields/{id}

Soft deactivate (set `active = false`). Cannot delete if used in existing records.

---

## Line Column Definitions

### GET /admin/line-columns

**Query**: `module`

### POST /admin/line-columns

**Request**:
```json
{
  "module": "sales_invoice",
  "key": "batch_no",
  "label": "Batch No",
  "input_type": "text",
  "show_on_screen": true,
  "show_on_pdf": false,
  "sort_order": 1
}
```

### PUT /admin/line-columns/{id}
### DELETE /admin/line-columns/{id}

---

## Backup & Restore

### GET /admin/backups

List backups with status, size, date.  
**Roles**: admin

### POST /admin/backups

Trigger manual backup.  
**Roles**: admin  
**Response 202**: `{ "data": { "backup_id": 5, "status": "pending" } }`

### GET /admin/backups/{id}

Get backup status and download URL if completed.  
**Response**:
```json
{
  "data": {
    "id": 5,
    "status": "completed",
    "file_size_bytes": 2048000,
    "completed_at": "2026-05-10T08:30:00Z",
    "download_url": "/api/v1/admin/backups/5/download"
  }
}
```

### GET /admin/backups/{id}/download

Download backup ZIP directly (streamed).  
**Roles**: admin

### POST /admin/restore

Upload a backup ZIP to initiate restore preview.

**Roles**: admin  
**Content-Type**: multipart/form-data — `backup_file` (ZIP, max 500MB)  
**Response 200**:
```json
{
  "data": {
    "restore_token": "restore-abc123",
    "summary": {
      "backup_date": "2026-05-09T08:00:00Z",
      "database_tables": 28,
      "file_count": 145,
      "total_size_bytes": 2048000
    },
    "warning": "This will overwrite all current data. Confirm to proceed."
  }
}
```

### POST /admin/restore/confirm

**Roles**: admin  
**Request**: `{ "restore_token": "restore-abc123", "confirmed": true }`  
**Response 202**: Restore job queued

---

## Activity Log

### GET /admin/activity-log

**Roles**: admin  
**Query**: `level` (info/warning/error/critical), `module`, `from_date`, `to_date`, `page`

**Response 200**:
```json
{
  "data": [
    {
      "id": 100,
      "level": "critical",
      "module": "backup",
      "message": "Scheduled backup failed: Google Drive connection timeout",
      "user_id": null,
      "created_at": "2026-05-10T02:00:15Z"
    }
  ]
}
```

---

## Tenant Management (Super-Admin only)

> These endpoints are on the central API and require a super-admin token (not tenant-level admin).

### GET /super/tenants
### POST /super/tenants

Provision a new tenant database and run migrations.  
**Request**: `{ "name", "code", "subdomain", "plan" }`  
**Response 201**: Tenant record; DB creation and migration happens synchronously (or via queue with status tracking)

### PUT /super/tenants/{id}
### DELETE /super/tenants/{id}

Deactivate tenant (does not drop DB).
