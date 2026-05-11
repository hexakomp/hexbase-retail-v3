# API Contract: Receipts, Payments, Expenses

**Base**: `/api/v1`  
**Auth**: Required

---

## Receipts

### GET /receipts

**Roles**: admin, acc, view  
**Query**: `search`, `customer_id`, `mode`, `from_date`, `to_date`, `status`, `page`

### POST /receipts

**Roles**: admin, acc, billing  
**Validation**:
- `receipt_date`: required
- `customer_id`: required
- `amount`: required, numeric > 0
- `mode`: required, enum
- `bank_account_id`: required if mode != `cash`
- `allocations[].allocated_amount`: sum of allocations ≤ amount

**Request**:
```json
{
  "receipt_date": "2026-05-10",
  "customer_id": 1,
  "amount": "10000.00",
  "mode": "upi",
  "bank_account_id": 2,
  "reference_number": "UPI-20260510-ABCD1234",
  "reference_date": "2026-05-10",
  "narration": "Payment received via UPI",
  "status": "posted",
  "custom_fields": {},
  "allocations": [
    { "sales_invoice_id": 5, "allocated_amount": "8000.00" },
    { "sales_invoice_id": 6, "allocated_amount": "2000.00" }
  ]
}
```

**Response 201**: Receipt with `receipt_number`, allocated invoices updated  
**Side effects on `posted`**: double-entry postings, `outstanding_amount` on invoices reduced, advance amount stored if allocations < total amount

### GET /receipts/{id}
**Roles**: admin, acc, billing, view

### PUT /receipts/{id}
Edit draft only. **Roles**: admin, acc

### POST /receipts/{id}/cancel
**Roles**: admin, acc  
**Side effects**: reversal postings, outstanding amounts restored

---

## Payments

### GET /payments

**Roles**: admin, acc, view  
**Query**: `search`, `vendor_id`, `mode`, `from_date`, `to_date`, `status`, `page`

### POST /payments

**Roles**: admin, acc  
**Validation** mirrors receipts but with `vendor_id` and purchase invoice allocations.

**Request**:
```json
{
  "payment_date": "2026-05-10",
  "vendor_id": 3,
  "amount": "4200.00",
  "mode": "neft",
  "bank_account_id": 2,
  "reference_number": "NEFT202605100001",
  "narration": "Payment against PI-2026-0045",
  "status": "posted",
  "custom_fields": {},
  "allocations": [
    { "purchase_invoice_id": 10, "allocated_amount": "4200.00" }
  ]
}
```

**Response 201**: Payment with `payment_number`  
**Side effects on `posted`**: double-entry postings, `outstanding_amount` on purchase invoices reduced

### GET /payments/{id}
### PUT /payments/{id}
### POST /payments/{id}/cancel

---

## Expenses

### GET /expenses

**Roles**: admin, acc, view  
**Query**: `search`, `category`, `mode`, `from_date`, `to_date`, `status`, `page`

### POST /expenses

**Roles**: admin, acc  
**Validation**:
- `expense_date`: required
- `category`: required
- `amount`: required, numeric > 0
- `mode`: required

**Request**:
```json
{
  "expense_date": "2026-05-10",
  "category": "Office Supplies",
  "vendor_id": null,
  "payee_name": "Ram Stationers",
  "amount": "500.00",
  "gst_applicable": true,
  "gst_rate": "18.00",
  "cgst_amount": "38.14",
  "sgst_amount": "38.14",
  "igst_amount": "0.00",
  "itc_eligible": false,
  "mode": "cash",
  "bank_account_id": null,
  "notes": "Pens and notebooks",
  "status": "posted"
}
```

**Response 201**: Expense with double-entry postings  
**Note**: Attachment upload via separate `POST /expenses/{id}/attachment` (same pattern as purchase invoices)

### GET /expenses/{id}
### PUT /expenses/{id}
Edit draft only.

### POST /expenses/{id}/cancel

### POST /expenses/{id}/attachment
Upload receipt scan. **Content-Type**: multipart/form-data
