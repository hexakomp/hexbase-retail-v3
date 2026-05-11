# API Contract: Purchases (Purchase Invoices, Purchase Orders, Debit Notes)

**Base**: `/api/v1`  
**Auth**: Required

---

## Purchase Invoices

### GET /purchase-invoices

**Roles**: admin, acc, view  
**Query**: `search`, `vendor_id`, `from_date`, `to_date`, `status`, `page`

### POST /purchase-invoices

**Roles**: admin, acc  
**Validation**:
- `entry_date`: required
- `vendor_id`: required
- `lines[].hsn_sac`: required
- `lines[].itc_eligible`: required boolean

**Request**:
```json
{
  "vendor_invoice_number": "VND-2026-445",
  "vendor_invoice_date": "2026-05-08",
  "entry_date": "2026-05-10",
  "vendor_id": 3,
  "purchase_order_id": null,
  "reverse_charge": false,
  "narration": "Purchase of sugar",
  "status": "posted",
  "custom_fields": {},
  "lines": [
    {
      "product_id": 1,
      "description": "White Sugar 1kg",
      "hsn_sac": "1701",
      "quantity": "100.00",
      "uom": "KGS",
      "rate": "40.00",
      "taxable_value": "4000.00",
      "gst_rate": "5.00",
      "cgst_rate": "2.50",
      "sgst_rate": "2.50",
      "igst_rate": "0.00",
      "cgst_amount": "100.00",
      "sgst_amount": "100.00",
      "igst_amount": "0.00",
      "cess_amount": "0.00",
      "itc_eligible": true,
      "line_total": "4200.00",
      "custom_columns": {}
    }
  ]
}
```

**Response 201**: Full purchase invoice with `voucher_number`  
**Side effects on `posted`**: double-entry postings, stock movements (quantity_in), PO status updated if linked

### GET /purchase-invoices/{id}
**Roles**: admin, acc, view

### PUT /purchase-invoices/{id}
Edit draft only. **Roles**: admin, acc

### POST /purchase-invoices/{id}/cancel
**Roles**: admin, acc  
**Response 409**: Cannot cancel if payment allocations exist

### POST /purchase-invoices/{id}/attachment
Upload scanned invoice PDF/image.

**Roles**: admin, acc  
**Content-Type**: `multipart/form-data`  
**Request**: `file` (PDF/JPG/PNG, max 10MB)  
**Response 200**: `{ "data": { "attachment_path": "..." } }`

---

## Purchase Orders

### GET /purchase-orders

**Roles**: admin, acc, view  
**Query**: `search`, `vendor_id`, `status`, `from_date`, `to_date`, `page`

### POST /purchase-orders

**Roles**: admin, acc  
**Request**:
```json
{
  "po_date": "2026-05-10",
  "delivery_date": "2026-05-17",
  "vendor_id": 3,
  "terms_conditions": "Delivery by 17 May",
  "status": "open",
  "lines": [
    {
      "product_id": 1,
      "description": "White Sugar 1kg",
      "quantity": "200.00",
      "uom": "KGS",
      "rate": "40.00",
      "line_total": "8000.00"
    }
  ]
}
```

**Response 201**: PO with `po_number`

### GET /purchase-orders/{id}
### PUT /purchase-orders/{id}
### POST /purchase-orders/{id}/cancel
### GET /purchase-orders/{id}/pdf

---

## Debit Notes

### GET /debit-notes

**Roles**: admin, acc, view  
**Query**: `search`, `vendor_id`, `original_purchase_invoice_id`, `status`, `page`

### POST /debit-notes

**Roles**: admin, acc  
**Request** mirrors purchase invoice structure; additional fields:
```json
{
  "original_purchase_invoice_id": 10,
  "reason": "Goods returned to vendor",
  "status": "posted",
  "lines": [ ... ]
}
```
**Side effects on `posted`**: reversal postings; stock movements (quantity_out); payable reduced.

### GET /debit-notes/{id}
### PUT /debit-notes/{id}
### POST /debit-notes/{id}/cancel
