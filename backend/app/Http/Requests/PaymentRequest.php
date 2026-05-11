<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class PaymentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'payment_date'                          => ['required', 'date'],
            'vendor_id'                             => ['required', 'integer', 'exists:tenant.vendors,id'],
            'bank_account_id'                       => ['nullable', 'integer', 'exists:tenant.bank_accounts,id'],
            'payment_mode'                          => ['nullable', 'in:cash,bank_transfer,cheque,upi,card,other'],
            'reference_number'                      => ['nullable', 'string', 'max:100'],
            'amount'                                => ['required', 'numeric', 'gt:0'],
            'tds_amount'                            => ['nullable', 'numeric', 'min:0'],
            'narration'                             => ['nullable', 'string', 'max:500'],
            'notes'                                 => ['nullable', 'string', 'max:1000'],
            'status'                                => ['nullable', 'in:draft,confirmed'],
            'custom_fields'                         => ['nullable', 'array'],

            'allocations'                           => ['nullable', 'array'],
            'allocations.*.purchase_invoice_id'     => ['required', 'integer', 'exists:tenant.purchase_invoices,id'],
            'allocations.*.allocated_amount'        => ['required', 'numeric', 'gt:0'],
        ];
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($v) {
            $allocs = $this->input('allocations', []);
            $total  = collect($allocs)->sum('allocated_amount');
            $amount = (float) $this->input('amount', 0);
            $tds    = (float) $this->input('tds_amount', 0);

            if ($total > ($amount - $tds)) {
                $v->errors()->add(
                    'allocations',
                    'Total allocated amount exceeds net payable (amount - TDS).'
                );
            }
        });
    }
}
