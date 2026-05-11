# API Contract: Sales (Invoices, Quotations, Credit Notes, Delivery Challans)

**Base**: `/api/v1`  
**Auth**: Required

---

## Sales Invoices

### GET /sales-invoices

**Roles**: admin, acc, billing, view  
**Query**: `search`, `customer_id`, `from_date`, `to_date`, `status`, `invoice_type`, `page`

### POST /sales-invoices/calculate

**Preview tax calculations without saving.** Used by Flutter form on every line change.

**Roles**: admin, acc, billing  
**Request**:
```json
{
  "customer_id": 1,
  "place_of_supply": "29",
  "invoice_type": "b2b",
  "lines": [
    {
      "product_id": 1,
      "quantity": "10.00",
      "rate": "100.00",
      "discount_percent": "5.00",
      "gst_rate": "18.00"
    }
  ]
}
```

**Response 200**:
```json
{
  "data": {
    "lines": [
      {
        "product_id": 1,
        "taxable_value": "950.00",
        "cgst_rate": "9.00",
        "sgst_rate": "9.00",
        "igst_rate": "0.00",
        "cgst_amount": "85.50",
        "sgst_amount": "85.50",
        "igst_amount": "0.00",
        "cess_amount": "0.00",
        "line_total": "1121.00"
      }
    ],
    "taxable_total": "950.00",
    "cgst_total": "85.50",
    "sgst_total": "85.50",
    "igst_total": "0.00",
    "cess_total": "0.00",
    "grand_total_exact": "1121.00",
    "round_off": "0.00",
    "grand_total": "1121.00"
  }
}
```

### POST /sales-invoices

Save invoice (draft or post).

**Roles**: admin, acc, billing  
**Validation**:
- `invoice_date`: required, date
- `customer_id`: required, exists
- `place_of_supply`: required, 2-char state code
- `invoice_type`: required, enum
- `lines`: required, min 1 item
- `lines[].hsn_sac`: required
- `lines[].quantity`, `rate`: required, numeric > 0
- `status`: `draft` | `posted`

**Request**:
```json
{
  "invoice_date": "2026-05-10",
  "customer_id": 1,
  "place_of_supply": "29",
  "invoice_type": "b2b",
  "payment_terms": "Net 30",
  "due_date": "2026-06-09",
  "narration": "Against PO #123",
  "status": "posted",
  "custom_fields": { "dc_no": "DC-001", "vehicle_no": "KA01AB1234" },
  "lines": [
    {
      "product_id": 1,
      "description": "White Sugar 1kg",
      "hsn_sac": "1701",
      "quantity": "10.00",
      "uom": "KGS",
      "rate": "100.00",
      "discount_percent": "5.00",
      "gst_rate": "18.00",
      "custom_columns": { "batch": "B001" }
    }
  ]
}
```

**Response 201**: Full invoice with computed tax values and `invoice_number`  
**Response 422**: Validation errors  
**Side effects on `posted`**: double-entry ledger entries created, stock movements created

### GET /sales-invoices/{id}

**Roles**: admin, acc, billing, view  
Returns full invoice with lines, tax breakup, allocations.

### PUT /sales-invoices/{id}

Edit invoice. **Only draft invoices can be edited.**  
**Roles**: admin, acc, billing

### POST /sales-invoices/{id}/cancel

Cancel invoice (soft). Posts reversal ledger entries.  
**Roles**: admin, acc  
**Request**: `{ "reason": "Customer cancellation" }`  
**Response 409**: Cannot cancel if allocations exist

### GET /sales-invoices/{id}/pdf

Generate and return PDF.

**Roles**: admin, acc, billing, view  
**Response**: `{ "data": { "pdf_url": "/storage/pdfs/INV-2026-0001.pdf", "inline_url": "..." } }`  
> PDF generation is synchronous (≤10 s per SC-011); loading indicator shown on client.

---

## Quotations

### GET /quotations
**Query**: `search`, `customer_id`, `status`, `from_date`, `to_date`, `page`

### POST /quotations
**Request** mirrors sales invoice but without GST fields at header level; lines include rates for preview calculation.  
**Status**: `draft` | `sent`

### GET /quotations/{id}
### PUT /quotations/{id}
Edit draft/sent quotations only.

### POST /quotations/{id}/convert
Convert accepted quotation to sales invoice.

**Roles**: admin, acc, billing  
**Request**: `{ "invoice_date": "2026-05-10", "status": "draft" }`  
**Response 200**: `{ "data": { "sales_invoice_id": 42 } }`  
**Response 409**: Quotation not in `accepted` status or already converted  
**Response 422**: Validity date expired (warning, not hard block — client can confirm)

### POST /quotations/{id}/cancel
### GET /quotations/{id}/pdf

---

## Credit Notes

### GET /credit-notes
**Query**: `search`, `customer_id`, `original_invoice_id`, `status`, `from_date`, `to_date`, `page`

### POST /credit-notes

**Roles**: admin, acc  
**Request** mirrors sales invoice structure; additional fields:
```json
{
  "original_invoice_id": 5,
  "reason": "Goods returned",
  "status": "posted",
  "lines": [ ... ]
}
```
**Side effects on `posted`**: reversal double-entry entries; stock movements (goods returned); GSTR-1 amendment data captured.

### GET /credit-notes/{id}
### PUT /credit-notes/{id}
Edit draft only.

### POST /credit-notes/{id}/cancel
### GET /credit-notes/{id}/pdf

---

## Delivery Challans

### GET /delivery-challans
**Query**: `search`, `customer_id`, `status`, `from_date`, `to_date`, `page`

### POST /delivery-challans

**Roles**: admin, acc, billing  
**Request**:
```json
{
  "dc_date": "2026-05-10",
  "customer_id": 1,
  "narration": "Dispatch to site",
  "status": "dispatched",
  "lines": [
    {
      "product_id": 1,
      "description": "White Sugar 1kg",
      "quantity": "5.00",
      "uom": "KGS"
    }
  ]
}
```
> No accounting or inventory postings in Phase 1 (FR-013a).

### GET /delivery-challans/{id}
### PUT /delivery-challans/{id}
Edit draft only.

### POST /delivery-challans/{id}/cancel
### GET /delivery-challans/{id}/pdf
