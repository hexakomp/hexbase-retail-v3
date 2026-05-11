<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title>Tax Invoice — {{ $invoice->invoice_number }}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'DejaVu Sans', sans-serif; font-size: 9pt; color: #111; }

        .page { width: 100%; padding: 16px; }

        /* Header */
        .header-table { width: 100%; border-collapse: collapse; margin-bottom: 6px; }
        .header-table td { vertical-align: top; padding: 4px; }
        .company-name { font-size: 14pt; font-weight: bold; color: #1a237e; }
        .doc-title { font-size: 13pt; font-weight: bold; text-align: right; color: #1a237e; }

        /* GST registration badge */
        .gstin-badge { background: #e8eaf6; padding: 3px 8px; font-size: 8pt; border-radius: 3px; margin-top: 4px; display: inline-block; }

        /* Info tables */
        .info-box { border: 1px solid #9e9e9e; border-radius: 3px; padding: 6px 8px; margin-bottom: 6px; }
        .info-label { font-size: 7.5pt; color: #555; font-weight: bold; text-transform: uppercase; }
        .info-value { font-size: 9pt; color: #111; margin-top: 1px; }

        .two-col { width: 100%; border-collapse: collapse; margin-bottom: 6px; }
        .two-col td { width: 50%; vertical-align: top; padding-right: 6px; }
        .two-col td:last-child { padding-right: 0; }

        /* Line items table */
        .lines-table { width: 100%; border-collapse: collapse; margin-bottom: 6px; }
        .lines-table th {
            background: #1a237e; color: #fff; padding: 5px 4px;
            font-size: 8pt; text-align: center; border: 1px solid #1a237e;
        }
        .lines-table td { border: 1px solid #bdbdbd; padding: 4px; font-size: 8.5pt; vertical-align: top; }
        .lines-table tr:nth-child(even) td { background: #f5f5f5; }
        .text-right { text-align: right; }
        .text-center { text-align: center; }

        /* Tax summary */
        .totals-table { width: 60%; margin-left: auto; border-collapse: collapse; margin-bottom: 6px; }
        .totals-table td { padding: 3px 6px; font-size: 9pt; }
        .totals-table .grand-total td { font-weight: bold; font-size: 10pt; border-top: 2px solid #1a237e; background: #e8eaf6; }

        /* Amount in words */
        .amount-words { font-style: italic; font-size: 8.5pt; color: #444; margin-bottom: 6px; }

        /* GST summary */
        .gst-summary-table { width: 100%; border-collapse: collapse; margin-bottom: 6px; }
        .gst-summary-table th { background: #e8eaf6; padding: 4px; font-size: 8pt; border: 1px solid #9e9e9e; }
        .gst-summary-table td { border: 1px solid #bdbdbd; padding: 4px; font-size: 8.5pt; text-align: center; }

        /* Footer */
        .footer-table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        .footer-table td { vertical-align: bottom; padding: 4px; }
        .signature-box { border-top: 1px solid #333; padding-top: 4px; font-size: 8pt; }

        hr { border: none; border-top: 1px solid #9e9e9e; margin: 8px 0; }

        .badge-original { color: #b71c1c; font-size: 7pt; font-weight: bold; letter-spacing: 1px; }
    </style>
</head>
<body>
<div class="page">

    {{-- ── Header ── --}}
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
                @if(!empty($companySettings->gstin))
                    <span class="gstin-badge">GSTIN: {{ $companySettings->gstin }}</span>
                @endif
                @if(!empty($companySettings->phone))
                    <div style="font-size:8pt; margin-top:2px;">Ph: {{ $companySettings->phone }}</div>
                @endif
            </td>
            <td style="width:40%; text-align:right;">
                <div class="doc-title">TAX INVOICE</div>
                <div class="badge-original">ORIGINAL FOR RECIPIENT</div>
                <div style="margin-top:8px; font-size:9pt;">
                    <strong>Invoice No:</strong> {{ $invoice->invoice_number }}<br>
                    <strong>Date:</strong> {{ $invoice->invoice_date->format('d-M-Y') }}<br>
                    @if($invoice->due_date)
                        <strong>Due Date:</strong> {{ $invoice->due_date->format('d-M-Y') }}<br>
                    @endif
                    @if($invoice->payment_terms)
                        <strong>Terms:</strong> {{ $invoice->payment_terms }}<br>
                    @endif
                    <strong>Place of Supply:</strong> {{ $invoice->place_of_supply }}
                </div>
            </td>
        </tr>
    </table>

    <hr>

    {{-- ── Bill To ── --}}
    <table class="two-col">
        <tr>
            <td>
                <div class="info-box">
                    <div class="info-label">Bill To</div>
                    <div class="info-value" style="font-weight:bold;">{{ $invoice->customer->name }}</div>
                    @if($invoice->customer->address)
                        <div class="info-value" style="font-size:8.5pt;">{{ $invoice->customer->address }}</div>
                    @endif
                    @if($invoice->customer_gstin)
                        <div class="info-value" style="font-size:8.5pt; margin-top:3px;">
                            <strong>GSTIN:</strong> {{ $invoice->customer_gstin }}
                        </div>
                    @endif
                    @if($invoice->customer->phone)
                        <div class="info-value" style="font-size:8pt;">Ph: {{ $invoice->customer->phone }}</div>
                    @endif
                </div>
            </td>
            <td>
                <div class="info-box">
                    <div class="info-label">Invoice Details</div>
                    <div class="info-value">
                        <strong>Type:</strong> {{ strtoupper($invoice->invoice_type) }}<br>
                        <strong>Supply:</strong> {{ ucfirst($invoice->supply_type) }}-state<br>
                        @if($invoice->narration)
                            <strong>Ref:</strong> {{ $invoice->narration }}
                        @endif
                    </div>
                </div>
            </td>
        </tr>
    </table>

    {{-- ── Line Items ── --}}
    <table class="lines-table">
        <thead>
            <tr>
                <th style="width:3%">#</th>
                <th style="width:25%">Item / Description</th>
                <th style="width:8%">HSN/SAC</th>
                <th style="width:6%">Qty</th>
                <th style="width:5%">UOM</th>
                <th style="width:9%">Rate</th>
                <th style="width:7%">Disc%</th>
                <th style="width:10%">Taxable Value</th>
                @if($invoice->supply_type === 'intra')
                    <th style="width:8%">CGST</th>
                    <th style="width:8%">SGST</th>
                @else
                    <th style="width:9%">IGST</th>
                @endif
                @if($invoice->lines->sum('cess_amount') > 0)
                    <th style="width:6%">Cess</th>
                @endif
                <th style="width:10%">Total</th>
            </tr>
        </thead>
        <tbody>
            @foreach($invoice->lines as $i => $line)
            <tr>
                <td class="text-center">{{ $i + 1 }}</td>
                <td>
                    {{ $line->product->name ?? $line->description }}
                    @if($line->description && $line->product)
                        <div style="font-size:7.5pt; color:#555;">{{ $line->description }}</div>
                    @endif
                </td>
                <td class="text-center">{{ $line->hsn_sac }}</td>
                <td class="text-right">{{ number_format($line->quantity, 2) }}</td>
                <td class="text-center">{{ $line->unit }}</td>
                <td class="text-right">{{ number_format($line->unit_price, 2) }}</td>
                <td class="text-right">{{ $line->discount_pct > 0 ? number_format($line->discount_pct, 2).'%' : '—' }}</td>
                <td class="text-right">{{ number_format($line->taxable_amount, 2) }}</td>
                @if($invoice->supply_type === 'intra')
                    <td class="text-right">
                        {{ number_format($line->cgst_rate, 1) }}%<br>
                        <strong>{{ number_format($line->cgst_amount, 2) }}</strong>
                    </td>
                    <td class="text-right">
                        {{ number_format($line->sgst_rate, 1) }}%<br>
                        <strong>{{ number_format($line->sgst_amount, 2) }}</strong>
                    </td>
                @else
                    <td class="text-right">
                        {{ number_format($line->igst_rate, 1) }}%<br>
                        <strong>{{ number_format($line->igst_amount, 2) }}</strong>
                    </td>
                @endif
                @if($invoice->lines->sum('cess_amount') > 0)
                    <td class="text-right">{{ number_format($line->cess_amount, 2) }}</td>
                @endif
                <td class="text-right"><strong>{{ number_format($line->line_total, 2) }}</strong></td>
            </tr>
            @endforeach
        </tbody>
    </table>

    {{-- ── GST Rate-Slab Summary ── --}}
    @php
        $gstSlabs = $invoice->lines->groupBy('gst_rate')->map(fn($lines, $rate) => [
            'rate'            => $rate,
            'taxable_amount'  => $lines->sum('taxable_amount'),
            'cgst_amount'     => $lines->sum('cgst_amount'),
            'sgst_amount'     => $lines->sum('sgst_amount'),
            'igst_amount'     => $lines->sum('igst_amount'),
            'cess_amount'     => $lines->sum('cess_amount'),
        ]);
    @endphp
    @if($gstSlabs->count() > 1 || ($gstSlabs->count() === 1 && $invoice->lines->count() > 1))
    <div style="margin-bottom:6px;">
        <div style="font-size:8pt; font-weight:bold; margin-bottom:3px;">GST Tax Summary</div>
        <table class="gst-summary-table">
            <thead>
                <tr>
                    <th>GST Rate</th>
                    <th>Taxable Amount</th>
                    @if($invoice->supply_type === 'intra')
                        <th>CGST Amount</th><th>SGST Amount</th>
                    @else
                        <th>IGST Amount</th>
                    @endif
                    @if($invoice->cess_amount > 0)<th>Cess</th>@endif
                    <th>Total Tax</th>
                </tr>
            </thead>
            <tbody>
                @foreach($gstSlabs as $slab)
                <tr>
                    <td>{{ $slab['rate'] }}%</td>
                    <td>{{ number_format($slab['taxable_amount'], 2) }}</td>
                    @if($invoice->supply_type === 'intra')
                        <td>{{ number_format($slab['cgst_amount'], 2) }}</td>
                        <td>{{ number_format($slab['sgst_amount'], 2) }}</td>
                    @else
                        <td>{{ number_format($slab['igst_amount'], 2) }}</td>
                    @endif
                    @if($invoice->cess_amount > 0)
                        <td>{{ number_format($slab['cess_amount'], 2) }}</td>
                    @endif
                    <td>{{ number_format($slab['cgst_amount'] + $slab['sgst_amount'] + $slab['igst_amount'] + $slab['cess_amount'], 2) }}</td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    @endif

    {{-- ── Totals ── --}}
    <table class="totals-table">
        <tr>
            <td>Subtotal</td>
            <td class="text-right">{{ number_format($invoice->subtotal, 2) }}</td>
        </tr>
        @if($invoice->discount_amount > 0)
        <tr>
            <td>Discount</td>
            <td class="text-right">({{ number_format($invoice->discount_amount, 2) }})</td>
        </tr>
        @endif
        <tr>
            <td>Taxable Amount</td>
            <td class="text-right">{{ number_format($invoice->taxable_amount, 2) }}</td>
        </tr>
        @if($invoice->cgst_amount > 0)
        <tr>
            <td>CGST</td>
            <td class="text-right">{{ number_format($invoice->cgst_amount, 2) }}</td>
        </tr>
        <tr>
            <td>SGST</td>
            <td class="text-right">{{ number_format($invoice->sgst_amount, 2) }}</td>
        </tr>
        @endif
        @if($invoice->igst_amount > 0)
        <tr>
            <td>IGST</td>
            <td class="text-right">{{ number_format($invoice->igst_amount, 2) }}</td>
        </tr>
        @endif
        @if($invoice->cess_amount > 0)
        <tr>
            <td>Cess</td>
            <td class="text-right">{{ number_format($invoice->cess_amount, 2) }}</td>
        </tr>
        @endif
        @if($invoice->round_off != 0)
        <tr>
            <td>Round Off</td>
            <td class="text-right">{{ number_format($invoice->round_off, 2) }}</td>
        </tr>
        @endif
        <tr class="grand-total">
            <td>Grand Total (INR)</td>
            <td class="text-right">₹ {{ number_format($invoice->total_amount, 2) }}</td>
        </tr>
    </table>

    {{-- ── Notes & Signature ── --}}
    <table class="footer-table">
        <tr>
            <td style="width:60%; vertical-align:top;">
                @if($invoice->notes)
                    <div style="font-size:8pt; margin-bottom:4px;"><strong>Notes:</strong><br>{{ $invoice->notes }}</div>
                @endif
                @if($invoice->terms_conditions)
                    <div style="font-size:8pt;"><strong>Terms & Conditions:</strong><br>{{ $invoice->terms_conditions }}</div>
                @endif
                <div style="margin-top:8px; font-size:7.5pt; color:#555;">
                    This is a computer-generated document. No signature required.
                </div>
            </td>
            <td style="width:40%; text-align:right;">
                <div class="signature-box">
                    <div style="height:40px;"></div>
                    <div><strong>For {{ $companySettings->company_name ?? '' }}</strong></div>
                    <div style="font-size:8pt;">Authorised Signatory</div>
                </div>
            </td>
        </tr>
    </table>

</div>
</body>
</html>
