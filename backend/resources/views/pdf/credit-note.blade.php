<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Credit Note — {{ $note->credit_note_number }}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'DejaVu Sans', sans-serif; font-size: 9pt; color: #111; }
        .page { width: 100%; padding: 16px; }
        .header-table { width: 100%; border-collapse: collapse; margin-bottom: 6px; }
        .header-table td { vertical-align: top; padding: 4px; }
        .company-name { font-size: 14pt; font-weight: bold; color: #1a237e; }
        .doc-title { font-size: 13pt; font-weight: bold; text-align: right; color: #b71c1c; }
        .info-box { border: 1px solid #9e9e9e; border-radius: 3px; padding: 6px 8px; margin-bottom: 6px; }
        .info-label { font-size: 7.5pt; color: #555; font-weight: bold; text-transform: uppercase; }
        .info-value { font-size: 9pt; color: #111; margin-top: 1px; }
        .two-col { width: 100%; border-collapse: collapse; margin-bottom: 6px; }
        .two-col td { width: 50%; vertical-align: top; padding-right: 6px; }
        .two-col td:last-child { padding-right: 0; }
        .lines-table { width: 100%; border-collapse: collapse; margin-bottom: 6px; }
        .lines-table th { background: #b71c1c; color: #fff; padding: 5px 4px; font-size: 8pt; text-align: center; border: 1px solid #b71c1c; }
        .lines-table td { border: 1px solid #bdbdbd; padding: 4px; font-size: 8.5pt; vertical-align: top; }
        .lines-table tr:nth-child(even) td { background: #fce4ec; }
        .text-right { text-align: right; }
        .text-center { text-align: center; }
        .totals-table { width: 60%; margin-left: auto; border-collapse: collapse; margin-bottom: 6px; }
        .totals-table td { padding: 3px 6px; font-size: 9pt; }
        .totals-table .grand-total td { font-weight: bold; font-size: 10pt; border-top: 2px solid #b71c1c; background: #fce4ec; }
        .footer-table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        .footer-table td { vertical-align: bottom; padding: 4px; }
        .signature-box { border-top: 1px solid #333; padding-top: 4px; font-size: 8pt; }
        hr { border: none; border-top: 1px solid #9e9e9e; margin: 8px 0; }
    </style>
</head>
<body>
<div class="page">

    <table class="header-table">
        <tr>
            <td style="width:60%">
                @if(!empty($companySettings->logo_path))
                    <img src="{{ storage_path('app/' . $companySettings->logo_path) }}"
                         style="max-height:60px; margin-bottom:4px;" alt="Logo">
                @endif
                <div class="company-name">{{ $companySettings->company_name ?? 'Your Company' }}</div>
                @if(!empty($companySettings->address))
                    <div style="font-size:8pt; margin-top:2px;">{{ $companySettings->address }}</div>
                @endif
            </td>
            <td style="text-align:right; width:40%;">
                <div class="doc-title">CREDIT NOTE</div>
                <div style="font-size:9pt; margin-top:4px;">
                    <strong>No:</strong> {{ $note->credit_note_number }}<br>
                    <strong>Date:</strong> {{ $note->credit_note_date->format('d/m/Y') }}
                </div>
                <div style="margin-top:6px; color:#b71c1c; font-size:8pt; font-weight:bold;">
                    ORIGINAL FOR RECIPIENT
                </div>
            </td>
        </tr>
    </table>

    <hr>

    <table class="two-col">
        <tr>
            <td>
                <div class="info-box">
                    <div class="info-label">Issued To</div>
                    <div class="info-value" style="font-weight:bold;">{{ $note->customer->name }}</div>
                    @if($note->customer->gstin)
                        <div style="font-size:8pt; margin-top:2px;">GSTIN: {{ $note->customer->gstin }}</div>
                    @endif
                    @if($note->customer->billing_address)
                        <div style="font-size:8pt; margin-top:2px;">{{ $note->customer->billing_address }}</div>
                    @endif
                </div>
            </td>
            <td>
                <div class="info-box">
                    @if($note->salesInvoice)
                        <div class="info-label">Against Invoice</div>
                        <div class="info-value">{{ $note->salesInvoice->invoice_number }}</div>
                        <div style="font-size:8pt;">Dated: {{ $note->salesInvoice->invoice_date->format('d/m/Y') }}</div>
                    @endif
                    @if($note->reason)
                        <div class="info-label" style="margin-top:6px;">Reason</div>
                        <div class="info-value">{{ $note->reason }}</div>
                    @endif
                </div>
            </td>
        </tr>
    </table>

    <table class="lines-table">
        <thead>
            <tr>
                <th style="width:4%">#</th>
                <th style="width:28%">Item / Description</th>
                <th style="width:8%">HSN/SAC</th>
                <th style="width:6%">Qty</th>
                <th style="width:6%">Unit</th>
                <th style="width:10%">Rate</th>
                <th style="width:8%">Disc%</th>
                <th style="width:10%">Taxable</th>
                <th style="width:10%">GST</th>
                <th style="width:10%">Total</th>
            </tr>
        </thead>
        <tbody>
            @foreach($note->lines as $i => $line)
            <tr>
                <td class="text-center">{{ $i + 1 }}</td>
                <td>{{ $line->product->name ?? $line->description }}</td>
                <td class="text-center">{{ $line->hsn_sac }}</td>
                <td class="text-right">{{ $line->quantity }}</td>
                <td class="text-center">{{ $line->unit }}</td>
                <td class="text-right">{{ number_format($line->unit_price, 2) }}</td>
                <td class="text-center">{{ $line->discount_pct }}%</td>
                <td class="text-right">{{ number_format($line->taxable_amount, 2) }}</td>
                <td class="text-right">{{ number_format($line->tax_amount, 2) }}</td>
                <td class="text-right">{{ number_format($line->line_total, 2) }}</td>
            </tr>
            @endforeach
        </tbody>
    </table>

    <table class="totals-table">
        <tr><td>Subtotal (Taxable)</td><td class="text-right">₹ {{ number_format($note->subtotal, 2) }}</td></tr>
        @if($note->cgst_amount > 0)
        <tr><td>CGST</td><td class="text-right">₹ {{ number_format($note->cgst_amount, 2) }}</td></tr>
        <tr><td>SGST</td><td class="text-right">₹ {{ number_format($note->sgst_amount, 2) }}</td></tr>
        @endif
        @if($note->igst_amount > 0)
        <tr><td>IGST</td><td class="text-right">₹ {{ number_format($note->igst_amount, 2) }}</td></tr>
        @endif
        <tr class="grand-total">
            <td>Credit Amount</td>
            <td class="text-right">₹ {{ number_format($note->total_amount, 2) }}</td>
        </tr>
    </table>

    <hr>

    <table class="footer-table">
        <tr>
            <td style="width:60%">
                <div style="font-size:8pt; color:#555;">
                    This credit note is computer-generated and does not require a signature.
                </div>
            </td>
            <td style="width:40%; text-align:center;">
                <div class="signature-box">
                    Authorised Signatory<br>
                    {{ $companySettings->company_name ?? '' }}
                </div>
            </td>
        </tr>
    </table>

</div>
</body>
</html>
