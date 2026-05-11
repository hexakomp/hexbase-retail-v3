<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class PurchaseInvoiceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Role-checked via middleware
    }

    public function rules(): array
    {
        return [
            'entry_date'                    => ['required', 'date'],
            'vendor_invoice_number'         => ['nullable', 'string', 'max:50'],
            'vendor_invoice_date'           => ['nullable', 'date'],
            'due_date'                      => ['nullable', 'date'],
            'vendor_id'                     => ['required', 'integer', 'exists:tenant.vendors,id'],
            'supply_type'                   => ['nullable', 'in:intra,inter,import'],
            'reverse_charge'                => ['nullable', 'boolean'],
            'purchase_order_id'             => ['nullable', 'integer', 'exists:tenant.purchase_orders,id'],
            'narration'                     => ['nullable', 'string', 'max:500'],
            'notes'                         => ['nullable', 'string', 'max:1000'],
            'status'                        => ['nullable', 'in:draft,posted'],
            'custom_fields'                 => ['nullable', 'array'],

            'lines'                         => ['required', 'array', 'min:1'],
            'lines.*.product_id'            => ['required', 'integer', 'exists:tenant.products,id'],
            'lines.*.description'           => ['nullable', 'string', 'max:500'],
            'lines.*.hsn_sac'               => ['required', 'string', 'max:10'],
            'lines.*.quantity'              => ['required', 'numeric', 'gt:0'],
            'lines.*.unit'                  => ['nullable', 'string', 'max:20'],
            'lines.*.uom'                   => ['nullable', 'string', 'max:20'],
            'lines.*.rate'                  => ['required', 'numeric', 'min:0'],
            'lines.*.discount_percent'      => ['nullable', 'numeric', 'min:0', 'max:100'],
            'lines.*.gst_rate'              => ['required', 'numeric', 'min:0'],
            'lines.*.cess_rate'             => ['nullable', 'numeric', 'min:0'],
            'lines.*.itc_eligible'          => ['required', 'boolean'],
            'lines.*.custom_columns'        => ['nullable', 'array'],
        ];
    }

    public function messages(): array
    {
        return [
            'vendor_id.exists'              => 'The selected vendor does not exist.',
            'lines.required'                => 'At least one line item is required.',
            'lines.min'                     => 'At least one line item is required.',
            'lines.*.product_id.exists'     => 'Line :index: product does not exist.',
            'lines.*.hsn_sac.required'      => 'Line :index: HSN/SAC code is required.',
            'lines.*.quantity.gt'           => 'Line :index: quantity must be greater than zero.',
            'lines.*.rate.min'              => 'Line :index: rate cannot be negative.',
            'lines.*.itc_eligible.required' => 'Line :index: ITC eligibility is required.',
        ];
    }
}
