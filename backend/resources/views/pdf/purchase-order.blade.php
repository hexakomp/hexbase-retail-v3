<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
  body { font-family: DejaVu Sans, sans-serif; font-size: 12px; color: #333; margin: 0; padding: 0; }
  .header { background: #1a237e; color: #fff; padding: 20px 24px; }
  .header h1 { margin: 0; font-size: 22px; }
  .header p  { margin: 4px 0; font-size: 11px; }
  .section { padding: 16px 24px; }
  .grid-2 { display: table; width: 100%; }
  .col { display: table-cell; width: 50%; vertical-align: top; }
  .label { font-weight: bold; color: #555; font-size: 11px; margin-bottom: 4px; }
  table { width: 100%; border-collapse: collapse; margin-top: 8px; }
  th { background: #1a237e; color: #fff; text-align: left; padding: 6px 8px; font-size: 11px; }
  td { padding: 6px 8px; border-bottom: 1px solid #eee; font-size: 11px; }
  tr:nth-child(even) td { background: #f5f7ff; }
  .totals { margin-top: 16px; text-align: right; }
  .totals table { width: 260px; float: right; }
  .totals td { border-bottom: none; }
  .grand-total { font-weight: bold; font-size: 14px; color: #1a237e; }
  .badge { display: inline-block; padding: 3px 10px; border-radius: 12px; font-size: 11px; font-weight: bold; }
  .badge-draft { background: #fff8e1; color: #f57f17; }
  .badge-sent  { background: #e8f5e9; color: #2e7d32; }
  .footer { border-top: 1px solid #ccc; padding: 12px 24px; font-size: 10px; color: #888; }
</style>
</head>
<body>
<div class="header">
  <h1>Purchase Order</h1>
  <p>{{ $po->po_number }} &nbsp;|&nbsp; {{ \Carbon\Carbon::parse($po->po_date)->format('d M Y') }}</p>
</div>

<div class="section">
  <div class="grid-2">
    <div class="col">
      <div class="label">Vendor</div>
      <strong>{{ $po->vendor->name ?? '' }}</strong><br>
      {{ $po->vendor->gstin ?? '' }}<br>
      {{ $po->vendor->address ?? '' }}
    </div>
    <div class="col" style="text-align:right;">
      <span class="badge badge-{{ $po->status }}">{{ strtoupper($po->status) }}</span><br><br>
      @if($po->expected_delivery_date)
        <div class="label">Expected Delivery</div>
        {{ \Carbon\Carbon::parse($po->expected_delivery_date)->format('d M Y') }}
      @endif
    </div>
  </div>
</div>

<div class="section">
  <table>
    <thead>
      <tr>
        <th>#</th>
        <th>Description</th>
        <th>HSN/SAC</th>
        <th style="text-align:right;">Qty</th>
        <th style="text-align:right;">Unit Price</th>
        <th style="text-align:right;">GST%</th>
        <th style="text-align:right;">Amount</th>
      </tr>
    </thead>
    <tbody>
      @foreach($po->lines as $i => $line)
      <tr>
        <td>{{ $i + 1 }}</td>
        <td>{{ $line->product->name ?? $line->description }}</td>
        <td>{{ $line->hsn_sac ?? '' }}</td>
        <td style="text-align:right;">{{ number_format($line->quantity, 2) }}</td>
        <td style="text-align:right;">₹ {{ number_format($line->unit_price, 2) }}</td>
        <td style="text-align:right;">{{ $line->gst_rate }}%</td>
        <td style="text-align:right;">₹ {{ number_format($line->line_total, 2) }}</td>
      </tr>
      @endforeach
    </tbody>
  </table>

  <div class="totals">
    <table>
      <tr><td>Subtotal</td><td style="text-align:right;">₹ {{ number_format($po->subtotal, 2) }}</td></tr>
      @if($po->cgst_amount > 0)
      <tr><td>CGST</td><td style="text-align:right;">₹ {{ number_format($po->cgst_amount, 2) }}</td></tr>
      <tr><td>SGST</td><td style="text-align:right;">₹ {{ number_format($po->sgst_amount, 2) }}</td></tr>
      @endif
      @if($po->igst_amount > 0)
      <tr><td>IGST</td><td style="text-align:right;">₹ {{ number_format($po->igst_amount, 2) }}</td></tr>
      @endif
      <tr class="grand-total"><td>Total</td><td style="text-align:right;">₹ {{ number_format($po->total_amount, 2) }}</td></tr>
    </table>
    <div style="clear:both;"></div>
  </div>
</div>

@if($po->notes)
<div class="section">
  <div class="label">Notes</div>
  {{ $po->notes }}
</div>
@endif

<div class="footer">
  This is a computer generated purchase order.
</div>
</body>
</html>
