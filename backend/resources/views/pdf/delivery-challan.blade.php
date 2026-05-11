<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
  body { font-family: DejaVu Sans, sans-serif; font-size: 12px; color: #333; margin: 0; padding: 0; }
  .header { background: #004d40; color: #fff; padding: 20px 24px; }
  .header h1 { margin: 0; font-size: 22px; }
  .header p  { margin: 4px 0; font-size: 11px; }
  .section { padding: 16px 24px; }
  .grid-2 { display: table; width: 100%; }
  .col { display: table-cell; width: 50%; vertical-align: top; }
  .label { font-weight: bold; color: #555; font-size: 11px; margin-bottom: 4px; }
  .notice { background: #fff8e1; border-left: 4px solid #f9a825; padding: 10px 14px; margin-bottom: 12px; font-size: 11px; }
  table { width: 100%; border-collapse: collapse; margin-top: 8px; }
  th { background: #004d40; color: #fff; text-align: left; padding: 6px 8px; font-size: 11px; }
  td { padding: 6px 8px; border-bottom: 1px solid #eee; font-size: 11px; }
  tr:nth-child(even) td { background: #f1f8f7; }
  .totals { margin-top: 16px; text-align: right; }
  .totals table { width: 200px; float: right; }
  .totals td { border-bottom: none; }
  .grand-total { font-weight: bold; font-size: 14px; color: #004d40; }
  .badge { display: inline-block; padding: 3px 10px; border-radius: 12px; font-size: 11px; font-weight: bold; }
  .badge-draft       { background: #fff8e1; color: #f57f17; }
  .badge-dispatched  { background: #e8f5e9; color: #2e7d32; }
  .footer { border-top: 1px solid #ccc; padding: 12px 24px; font-size: 10px; color: #888; }
  .sig-box { border-top: 1px solid #aaa; margin-top: 40px; width: 180px; text-align: center; font-size: 10px; color: #555; }
</style>
</head>
<body>
<div class="header">
  <h1>Delivery Challan</h1>
  <p>{{ $dc->dc_number }} &nbsp;|&nbsp; {{ \Carbon\Carbon::parse($dc->dc_date)->format('d M Y') }}</p>
</div>

<div class="section">
  <div class="notice">
    This document is for delivery purposes only. It is not a Tax Invoice.
  </div>

  <div class="grid-2">
    <div class="col">
      <div class="label">Deliver To</div>
      <strong>{{ $dc->customer->name ?? '' }}</strong><br>
      {{ $dc->customer->address ?? '' }}
    </div>
    <div class="col" style="text-align:right;">
      <span class="badge badge-{{ $dc->status }}">{{ strtoupper($dc->status) }}</span><br><br>
      @if($dc->vehicle_number)
        <div class="label">Vehicle No.</div>
        {{ $dc->vehicle_number }}<br>
      @endif
      @if($dc->transporter_name)
        <div class="label">Transporter</div>
        {{ $dc->transporter_name }}<br>
      @endif
      @if($dc->destination)
        <div class="label">Destination</div>
        {{ $dc->destination }}
      @endif
    </div>
  </div>
</div>

<div class="section">
  <table>
    <thead>
      <tr>
        <th>#</th>
        <th>Item Description</th>
        <th style="text-align:right;">Qty</th>
        <th>Unit</th>
        <th style="text-align:right;">Rate</th>
        <th style="text-align:right;">Amount</th>
      </tr>
    </thead>
    <tbody>
      @foreach($dc->lines as $i => $line)
      <tr>
        <td>{{ $i + 1 }}</td>
        <td>{{ $line->product->name ?? $line->description }}</td>
        <td style="text-align:right;">{{ number_format($line->quantity, 2) }}</td>
        <td>{{ $line->unit }}</td>
        <td style="text-align:right;">₹ {{ number_format($line->unit_price, 2) }}</td>
        <td style="text-align:right;">₹ {{ number_format($line->line_total, 2) }}</td>
      </tr>
      @endforeach
    </tbody>
  </table>

  <div class="totals">
    <table>
      <tr class="grand-total"><td>Total</td><td style="text-align:right;">₹ {{ number_format($dc->total_amount, 2) }}</td></tr>
    </table>
    <div style="clear:both;"></div>
  </div>
</div>

@if($dc->notes)
<div class="section">
  <div class="label">Notes</div>
  {{ $dc->notes }}
</div>
@endif

<div class="section">
  <div class="grid-2">
    <div class="col">
      <div class="sig-box">Receiver Signature &amp; Stamp</div>
    </div>
    <div class="col" style="text-align:right;">
      <div class="sig-box" style="margin-left:auto;">Authorised Signatory</div>
    </div>
  </div>
</div>

<div class="footer">
  This is a computer generated delivery challan.
</div>
</body>
</html>
