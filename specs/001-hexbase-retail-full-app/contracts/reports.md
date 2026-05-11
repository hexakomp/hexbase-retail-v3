# API Contract: Reports

**Base**: `/api/v1`  
**Auth**: Required  
**Common query params**: `from_date`, `to_date` (unless noted as financial year queries)

All report endpoints return JSON data by default.  
Add `?format=pdf` to any report endpoint to trigger PDF generation (queued; returns job ID for polling if async, or direct download if sync).

---

## GST Reports

### GET /reports/gstr1/b2b

B2B outward supplies list.

**Roles**: admin, acc, view  
**Query**: `from_date`, `to_date`

**Response 200**:
```json
{
  "data": {
    "period": "2026-04-01 to 2026-04-30",
    "summary": { "total_invoices": 45, "total_taxable": "450000.00", "total_tax": "81000.00" },
    "records": [
      {
        "gstin": "29AABCU9603R1ZX",
        "customer_name": "ABC Traders",
        "invoice_number": "INV-2026-0001",
        "invoice_date": "2026-04-05",
        "invoice_type": "b2b",
        "place_of_supply": "29",
        "taxable_value": "10000.00",
        "cgst": "900.00",
        "sgst": "900.00",
        "igst": "0.00",
        "cess": "0.00"
      }
    ]
  }
}
```

---

### GET /reports/gstr1/b2c

B2C aggregate summary. **Roles**: admin, acc, view

---

### GET /reports/gstr1/hsn-summary

HSN-wise aggregate: taxable value, CGST, SGST, IGST.

**Roles**: admin, acc, view  
**Response includes**: HSN code, description, UOM, quantity, taxable value, tax amounts.

---

### GET /reports/gstr1/document-summary

Count and value of invoices, credit notes, debit notes, revised invoices by type.

**Roles**: admin, acc, view

---

### GET /reports/gstr1/tax-liability

Tax liability summary grouped by GST rate slab.

**Roles**: admin, acc, view

---

### GET /reports/gstr3b/summary

GSTR-3B support summary: outward supplies total, eligible ITC, net tax payable.

**Roles**: admin, acc, view

---

### GET /reports/itc-register

ITC register from purchase invoices where `itc_eligible = true`.

**Roles**: admin, acc, view  
**Query**: `from_date`, `to_date`, `vendor_id`

---

### GET /reports/sales-tax-register

All sales invoices with tax breakup, chronological.

**Roles**: admin, acc, view

---

### GET /reports/purchase-tax-register

All purchase invoices with tax breakup.

**Roles**: admin, acc, view

---

## Financial Reports

### GET /reports/day-book

All vouchers in date order: sales invoices, purchase invoices, receipts, payments, expenses, adjustments.

**Roles**: admin, acc, view  
**Query**: `from_date`, `to_date`, `voucher_type`

---

### GET /reports/sales-register

Sales invoices with amounts, tax, outstanding. **Query**: `from_date`, `to_date`, `customer_id`

---

### GET /reports/purchase-register

Purchase invoices. **Query**: `from_date`, `to_date`, `vendor_id`

---

### GET /reports/receivables-ageing

Customer-wise outstanding broken into: current, 1–30 days, 31–60 days, 61–90 days, 90+ days.

**Roles**: admin, acc, view  
**Query**: `as_of_date`

---

### GET /reports/payables-ageing

Vendor-wise ageing. Same structure.

---

### GET /reports/cash-book

Cash ledger entries. **Query**: `from_date`, `to_date`

---

### GET /reports/bank-book

Bank ledger entries. **Query**: `from_date`, `to_date`, `bank_account_id`

---

### GET /reports/cash-flow

Cash inflow vs outflow summary by period.

---

### GET /reports/trial-balance

**Query**: `as_of_date`  
**Response**: All ledger accounts with debit/credit totals; `total_debit === total_credit` invariant.

---

### GET /reports/profit-loss

**Query**: `from_date`, `to_date`  
Income vs expense grouped by ledger account type.

---

### GET /reports/balance-sheet

**Query**: `as_of_date`  
Assets, liabilities, equity.

---

### GET /reports/expense-register

**Query**: `from_date`, `to_date`, `category`

---

## Inventory Reports

### GET /reports/stock-summary

Current stock, average cost, stock value for all products.

**Roles**: admin, acc, view  
**Query**: `category`, `low_stock_only`

---

### GET /reports/stock-ledger

Item-wise stock movement history.

**Query**: `product_id` (required), `from_date`, `to_date`

---

### GET /reports/low-stock

Products where `current_stock < min_stock_level`.

---

### GET /reports/stock-valuation

Stock valuation summary at a point in time.

**Query**: `as_of_date`
