<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ReceiptRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'receipt_date'                       => ['required', 'date'],
            'customer_id'                        => ['required', 'integer', 'exists:tenant.customers,id'],
            'bank_account_id'                    => ['nullable', 'integer', 'exists:tenant.bank_accounts,id'],
            'payment_mode'                       => ['nullable', 'in:cash,bank_transfer,cheque,upi,card,other'],
            'reference_number'                   => ['nullable', 'string', 'max:100'],
            'amount'                             => ['required', 'numeric', 'gt:0'],
            'narration'                          => ['nullable', 'string', 'max:500'],
            'notes'                              => ['nullable', 'string', 'max:1000'],
            'status'                             => ['nullable', 'in:draft,confirmed'],
            'custom_fields'                      => ['nullable', 'array'],

            'allocations'                        => ['nullable', 'array'],
            'allocations.*.sales_invoice_id'     => ['required', 'integer', 'exists:tenant.sales_invoices,id'],
            'allocations.*.allocated_amount'     => ['required', 'numeric', 'gt:0'],
        ];
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($v) {
            $allocs = $this->input('allocations', []);
            $total  = collect($allocs)->sum('allocated_amount');
            $amount = (float) $this->input('amount', 0);

            if ($total > $amount) {
                $v->errors()->add(
                    'allocations',
                    "Total allocated amount ({$total}) cannot exceed receipt amount ({$amount})."
                );
            }
        });
    }
}
