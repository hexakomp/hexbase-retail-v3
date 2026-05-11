<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SalesInvoiceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Role-checked via middleware
    }

    public function rules(): array
    {
        return [
            'invoice_date'               => ['required', 'date'],
            'due_date'                   => ['nullable', 'date', 'after_or_equal:invoice_date'],
            'customer_id'                => ['required', 'integer', 'exists:tenant.customers,id'],
            'place_of_supply'            => ['required', 'string', 'max:2'],
            'invoice_type'               => ['required', 'in:b2b,b2c,export'],
            'supply_type'                => ['nullable', 'in:intra,inter,export'],
            'payment_terms'              => ['nullable', 'string', 'max:100'],
            'narration'                  => ['nullable', 'string', 'max:500'],
            'notes'                      => ['nullable', 'string', 'max:1000'],
            'terms_conditions'           => ['nullable', 'string', 'max:2000'],
            'status'                     => ['nullable', 'in:draft,posted'],
            'custom_fields'              => ['nullable', 'array'],

            'lines'                      => ['required', 'array', 'min:1'],
            'lines.*.product_id'         => ['required', 'integer', 'exists:tenant.products,id'],
            'lines.*.description'        => ['nullable', 'string', 'max:500'],
            'lines.*.hsn_sac'            => ['required', 'string', 'max:10'],
            'lines.*.quantity'           => ['required', 'numeric', 'gt:0'],
            'lines.*.unit'               => ['nullable', 'string', 'max:20'],
            'lines.*.rate'               => ['required', 'numeric', 'min:0'],
            'lines.*.discount_percent'   => ['nullable', 'numeric', 'min:0', 'max:100'],
            'lines.*.gst_rate'           => ['required', 'numeric', 'min:0'],
            'lines.*.cess_rate'          => ['nullable', 'numeric', 'min:0'],
            'lines.*.custom_columns'     => ['nullable', 'array'],
        ];
    }

    public function messages(): array
    {
        return [
            'customer_id.exists'       => 'The selected customer does not exist.',
            'lines.required'           => 'At least one line item is required.',
            'lines.min'                => 'At least one line item is required.',
            'lines.*.product_id.exists' => 'Line :index: product does not exist.',
            'lines.*.hsn_sac.required' => 'Line :index: HSN/SAC code is required.',
            'lines.*.quantity.gt'      => 'Line :index: quantity must be greater than zero.',
            'lines.*.rate.min'         => 'Line :index: rate cannot be negative.',
        ];
    }
}
