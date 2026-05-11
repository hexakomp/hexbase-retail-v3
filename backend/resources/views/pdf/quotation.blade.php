<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quotation #{{ $quotation->quotation_number }}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: DejaVu Sans, Arial, sans-serif; font-size: 12px; color: #333; }
        .page { padding: 20px; }
        .header { display: flex; justify-content: space-between; margin-bottom: 20px; border-bottom: 2px solid #2563eb; padding-bottom: 12px; }
        .company-name { font-size: 20px; font-weight: bold; color: #2563eb; }
        .company-details { font-size: 10px; color: #666; margin-top: 4px; }
        .doc-title { font-size: 18px; font-weight: bold; text-align: right; color: #2563eb; }
        .doc-meta { font-size: 10px; text-align: right; color: #555; margin-top: 4px; }
        .validity-badge { display: inline-block; padding: 2px 8px; border-radius: 3px; font-size: 10px; font-weight: bold; }
        .valid { background: #dcfce7; color: #166534; }
        .expired { background: #fee2e2; color: #991b1b; }

        .parties { display: flex; gap: 20px; margin-bottom: 20px; }
        .party-box { flex: 1; border: 1px solid #e5e7eb; border-radius: 4px; padding: 10px; }
        .party-label { font-size: 9px; text-transform: uppercase; color: #6b7280; margin-bottom: 4px; letter-spacing: 0.05em; }
        .party-name { font-weight: bold; font-size: 13px; }
        .party-detail { font-size: 10px; color: #555; margin-top: 2px; }

        .items-table { width: 100%; border-collapse: collapse; margin-bottom: 16px; }
        .items-table thead tr { background: #2563eb; color: white; }
        .items-table thead th { padding: 8px; text-align: left; font-size: 11px; }
        .items-table thead th.right { text-align: right; }
        .items-table tbody tr:nth-child(even) { background: #f9fafb; }
        .items-table tbody td { padding: 7px 8px; font-size: 11px; border-bottom: 1px solid #f3f4f6; }
        .items-table tbody td.right { text-align: right; }

        .summary { display: flex; justify-content: flex-end; margin-bottom: 20px; }
        .summary-table { width: 300px; }
        .summary-table tr td { padding: 4px 8px; font-size: 11px; }
        .summary-table tr td:last-child { text-align: right; }
        .summary-table tr.total { font-weight: bold; font-size: 13px; border-top: 2px solid #2563eb; }
        .summary-table tr.total td { padding-top: 8px; }

        .terms { margin-bottom: 20px; }
        .terms h4 { font-size: 11px; font-weight: bold; margin-bottom: 4px; color: #374151; }
        .terms p { font-size: 10px; color: #6b7280; line-height: 1.5; }

        .footer { border-top: 1px solid #e5e7eb; padding-top: 12px; text-align: center; font-size: 9px; color: #9ca3af; }

        .gstin-row { font-size: 10px; color: #374151; margin-top: 2px; }
    </style>
</head>
<body>
<div class="page">
    <!-- Header -->
    <div class="header">
        <div>
            <div class="company-name">{{ $company['name'] ?? config('app.name') }}</div>
            @if(!empty($company['address']))
                <div class="company-details">{{ $company['address'] }}</div>
            @endif
            @if(!empty($company['gstin']))
                <div class="company-details">GSTIN: {{ $company['gstin'] }}</div>
            @endif
        </div>
        <div>
            <div class="doc-title">QUOTATION</div>
            <div class="doc-meta">#{{ $quotation->quotation_number }}</div>
            <div class="doc-meta">Date: {{ $quotation->quotation_date->format('d M Y') }}</div>
            <div class="doc-meta">
                Valid Till: {{ $quotation->validity_date->format('d M Y') }}
                @if($quotation->isExpired())
                    <span class="validity-badge expired">EXPIRED</span>
                @else
                    <span class="validity-badge valid">VALID</span>
                @endif
            </div>
        </div>
    </div>

    <!-- Bill To -->
    <div class="parties">
        <div class="party-box">
            <div class="party-label">Bill To</div>
            <div class="party-name">{{ $quotation->customer->name }}</div>
            @if($quotation->customer->billing_address)
                <div class="party-detail">{{ $quotation->customer->billing_address }}</div>
            @endif
            @if($quotation->customer->billing_city || $quotation->customer->billing_state)
                <div class="party-detail">{{ implode(', ', array_filter([$quotation->customer->billing_city, $quotation->customer->billing_state, $quotation->customer->billing_pincode])) }}</div>
            @endif
            @if($quotation->customer->gstin)
                <div class="gstin-row">GSTIN: {{ $quotation->customer->gstin }}</div>
            @endif
            @if($quotation->customer->phone)
                <div class="party-detail">Ph: {{ $quotation->customer->phone }}</div>
            @endif
        </div>

        <div class="party-box" style="background: #f8faff;">
            <div class="party-label">Quotation Summary</div>
            <div class="party-detail">Place of Supply: {{ $quotation->place_of_supply ?? '—' }}</div>
            <div class="party-detail" style="margin-top:8px;">Status: <strong>{{ strtoupper($quotation->status) }}</strong></div>
        </div>
    </div>

    <!-- Line Items -->
    <table class="items-table">
        <thead>
        <tr>
            <th>#</th>
            <th>Description</th>
            <th>HSN/SAC</th>
            <th class="right">Qty</th>
            <th>Unit</th>
            <th class="right">Rate</th>
            <th class="right">Disc.</th>
            <th class="right">Taxable</th>
            <th class="right">GST%</th>
            <th class="right">Tax</th>
            <th class="right">Total</th>
        </tr>
        </thead>
        <tbody>
        @foreach($quotation->lines as $i => $line)
            <tr>
                <td>{{ $i + 1 }}</td>
                <td>{{ $line->description }}</td>
                <td>{{ $line->hsn_sac ?? '—' }}</td>
                <td class="right">{{ number_format($line->quantity, 2) }}</td>
                <td>{{ $line->unit ?? '' }}</td>
                <td class="right">{{ number_format($line->unit_price, 2) }}</td>
                <td class="right">{{ $line->discount_amount > 0 ? number_format($line->discount_amount, 2) : '—' }}</td>
                <td class="right">{{ number_format($line->taxable_amount, 2) }}</td>
                <td class="right">{{ $line->gst_rate }}%</td>
                <td class="right">{{ number_format($line->cgst_amount + $line->sgst_amount + $line->igst_amount, 2) }}</td>
                <td class="right">{{ number_format($line->total_amount, 2) }}</td>
            </tr>
        @endforeach
        </tbody>
    </table>

    <!-- Summary -->
    <div class="summary">
        <table class="summary-table">
            <tr>
                <td>Taxable Amount</td>
                <td>₹{{ number_format($quotation->taxable_amount, 2) }}</td>
            </tr>
            @if($quotation->cgst_amount > 0)
                <tr>
                    <td>CGST</td>
                    <td>₹{{ number_format($quotation->cgst_amount, 2) }}</td>
                </tr>
            @endif
            @if($quotation->sgst_amount > 0)
                <tr>
                    <td>SGST</td>
                    <td>₹{{ number_format($quotation->sgst_amount, 2) }}</td>
                </tr>
            @endif
            @if($quotation->igst_amount > 0)
                <tr>
                    <td>IGST</td>
                    <td>₹{{ number_format($quotation->igst_amount, 2) }}</td>
                </tr>
            @endif
            @if(!empty($quotation->discount_amount) && $quotation->discount_amount > 0)
                <tr>
                    <td>Discount</td>
                    <td>-₹{{ number_format($quotation->discount_amount, 2) }}</td>
                </tr>
            @endif
            <tr class="total">
                <td>Total Amount</td>
                <td>₹{{ number_format($quotation->total_amount, 2) }}</td>
            </tr>
        </table>
    </div>

    @if($quotation->narration)
        <div class="terms">
            <h4>Narration</h4>
            <p>{{ $quotation->narration }}</p>
        </div>
    @endif

    @if($quotation->terms_conditions)
        <div class="terms">
            <h4>Terms & Conditions</h4>
            <p>{{ $quotation->terms_conditions }}</p>
        </div>
    @endif

    <div class="footer">
        This is a computer-generated quotation. Valid till {{ $quotation->validity_date->format('d M Y') }}.
    </div>
</div>
</body>
</html>
