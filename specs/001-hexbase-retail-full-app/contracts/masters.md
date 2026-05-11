# API Contract: Masters

**Base**: `/api/v1`  
**Auth**: Required for all endpoints

---

## Customers

### GET /customers

List customers with search and pagination.

**Roles**: admin, acc, billing, view  
**Query params**: `search` (name/GSTIN/mobile), `type`, `active`, `page`, `per_page`

**Response 200**:
```json
{
  "data": [
    {
      "id": 1,
      "code": "CUST-001",
      "name": "ABC Traders",
      "gstin": "29AABCU9603R1ZX",
      "billing_state": "Karnataka",
      "billing_state_code": "29",
      "customer_type": "regular",
      "mobile": "9876543210",
      "outstanding_balance": "12500.00",
      "active": true
    }
  ],
  "meta": { "pagination": { "total": 450, "per_page": 25, "current_page": 1, "last_page": 18 } }
}
```

### POST /customers

Create customer.

**Roles**: admin, acc  
**Validation**:
- `name`: required, max 200
- `gstin`: nullable, 15-char GST format
- `customer_type`: required, enum
- `billing_state_code`: required if customer_type is `regular` or `b2b`

**Request**:
```json
{
  "name": "ABC Traders",
  "trade_name": "ABC",
  "gstin": "29AABCU9603R1ZX",
  "customer_type": "regular",
  "billing_address": "123 MG Road",
  "billing_city": "Bengaluru",
  "billing_state": "Karnataka",
  "billing_state_code": "29",
  "billing_pincode": "560001",
  "mobile": "9876543210",
  "credit_limit": "50000.00",
  "credit_days": 30,
  "opening_balance": "5000.00",
  "opening_balance_type": "debit"
}
```

**Response 201**: Created customer  
**Response 409**: Duplicate GSTIN warning (returns `{ "duplicate_warning": true, "existing_id": 5 }`)

### GET /customers/{id}

**Roles**: admin, acc, billing, view  
Returns full customer record + `outstanding_balance`.

### PUT /customers/{id}

**Roles**: admin, acc

### DELETE /customers/{id}

Soft deactivate. **Roles**: admin  
**Response 409**: Cannot deactivate if outstanding balance > 0

### GET /customers/{id}/ledger

Customer ledger with date range.

**Query**: `from_date`, `to_date`, `page`  
**Roles**: admin, acc, view

---

## Vendors

### GET /vendors

**Roles**: admin, acc, view  
**Query**: `search`, `active`, `page`, `per_page`

### POST /vendors

**Roles**: admin, acc  
Fields mirror customers plus `tds_applicable`, `tds_rate`, `itc_notes`, `payment_terms_days`.

### GET /vendors/{id}
### PUT /vendors/{id}
### DELETE /vendors/{id}

Same patterns as customers.

### GET /vendors/{id}/ledger

Vendor ledger. **Roles**: admin, acc, view

---

## Products

### GET /products

**Roles**: admin, acc, billing, view  
**Query**: `search` (name/code/barcode/HSN), `type` (goods/service), `active`, `low_stock`, `page`, `per_page`

**Response 200**:
```json
{
  "data": [
    {
      "id": 1,
      "code": "PROD-001",
      "name": "White Sugar 1kg",
      "hsn_sac": "1701",
      "gst_rate": "5.00",
      "uom": "KGS",
      "selling_rate": "45.00",
      "current_stock": "120.00",
      "active": true
    }
  ]
}
```

### POST /products

**Roles**: admin, acc  
**Validation**:
- `name`: required
- `hsn_sac`: required if `type = goods`; SAC required if `type = service`
- `gst_rate`: required; must be valid GST slab

**Request**:
```json
{
  "code": "PROD-001",
  "name": "White Sugar 1kg",
  "type": "goods",
  "hsn_sac": "1701",
  "uom": "KGS",
  "gst_rate": "5.00",
  "cess_rate": "0.00",
  "selling_rate": "45.00",
  "purchase_rate": "40.00",
  "track_inventory": true,
  "min_stock_level": "10.00",
  "opening_stock_qty": "50.00",
  "opening_stock_value": "2000.00"
}
```

**Response 201**: Created product

### GET /products/{id}
### PUT /products/{id}
### DELETE /products/{id}

**Roles**: admin for delete; admin/acc for update

### GET /products/{id}/stock-ledger

Item-wise stock movement. **Query**: `from_date`, `to_date`  
**Roles**: admin, acc, view

---

## Barcode Lookup

### GET /products/by-barcode/{barcode}

Used by billing screens for fast product lookup.  
**Roles**: admin, acc, billing  
**Response**: Single product record or 404
