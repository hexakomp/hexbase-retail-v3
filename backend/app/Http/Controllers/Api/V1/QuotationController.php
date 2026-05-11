<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Quotation;
use App\Services\QuotationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class QuotationController extends Controller
{
    public function __construct(private QuotationService $service) {}

    public function index(Request $request): JsonResponse
    {
        $query = Quotation::with('customer')
            ->whereNull('deleted_at')
            ->orderByDesc('quotation_date');

        if ($status = $request->string('status')->trim()->toString()) {
            $query->where('status', $status);
        }

        if ($customerId = $request->integer('customer_id')) {
            $query->where('customer_id', $customerId);
        }

        if ($search = $request->string('search')->trim()->toString()) {
            $query->where(function ($q) use ($search) {
                $q->where('quotation_number', 'like', "%{$search}%")
                  ->orWhereHas('customer', fn ($c) => $c->where('name', 'like', "%{$search}%"));
            });
        }

        $quotations = $query->paginate($request->integer('per_page', 20));

        return response()->json([
            'data'    => $quotations->items(),
            'meta'    => [
                'current_page' => $quotations->currentPage(),
                'last_page'    => $quotations->lastPage(),
                'total'        => $quotations->total(),
            ],
            'message' => 'OK',
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate($this->rules());
        $quotation = $this->service->create($validated);

        return response()->json(['data' => $quotation, 'meta' => [], 'message' => 'Quotation created.'], 201);
    }

    public function show(Quotation $quotation): JsonResponse
    {
        $quotation->load('lines.product', 'customer', 'convertedInvoice');

        $data             = $quotation->toArray();
        $data['expired']  = $quotation->isExpired();

        return response()->json(['data' => $data, 'meta' => [], 'message' => 'OK']);
    }

    public function update(Request $request, Quotation $quotation): JsonResponse
    {
        $validated = $request->validate($this->rules($quotation->id));
        $updated   = $this->service->update($quotation, $validated);

        return response()->json(['data' => $updated, 'meta' => [], 'message' => 'Quotation updated.']);
    }

    public function destroy(Quotation $quotation): JsonResponse
    {
        if (in_array($quotation->status, ['converted'])) {
            abort(422, 'Cannot delete a converted quotation.');
        }

        $quotation->delete();

        return response()->json(['data' => null, 'meta' => [], 'message' => 'Quotation deleted.']);
    }

    public function post(Request $request, Quotation $quotation): JsonResponse
    {
        $updated = $this->service->post($quotation);

        return response()->json(['data' => $updated, 'meta' => [], 'message' => 'Quotation sent.']);
    }

    public function convert(Request $request, Quotation $quotation): JsonResponse
    {
        $invoice = $this->service->convert($quotation);

        return response()->json(['data' => $invoice, 'meta' => [], 'message' => 'Quotation converted to sales invoice.']);
    }

    private function rules(?int $id = null): array
    {
        return [
            'customer_id'       => ['required', 'integer'],
            'quotation_number'  => ['nullable', 'string', 'max:50'],
            'quotation_date'    => ['required', 'date'],
            'validity_date'     => ['required', 'date', 'after_or_equal:quotation_date'],
            'place_of_supply'   => ['nullable', 'string', 'max:50'],
            'narration'         => ['nullable', 'string'],
            'terms_conditions'  => ['nullable', 'string'],
            'custom_fields'     => ['nullable', 'array'],
            'lines'             => ['required', 'array', 'min:1'],
            'lines.*.product_id'      => ['nullable', 'integer'],
            'lines.*.description'     => ['required', 'string', 'max:500'],
            'lines.*.hsn_sac'         => ['nullable', 'string', 'max:10'],
            'lines.*.quantity'        => ['required', 'numeric', 'min:0.001'],
            'lines.*.unit'            => ['nullable', 'string', 'max:20'],
            'lines.*.unit_price'      => ['required', 'numeric', 'min:0'],
            'lines.*.discount_percent' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'lines.*.discount_amount' => ['nullable', 'numeric', 'min:0'],
            'lines.*.taxable_amount'  => ['required', 'numeric', 'min:0'],
            'lines.*.gst_rate'        => ['nullable', 'integer', Rule::in([0, 5, 12, 18, 28])],
            'lines.*.cgst_rate'       => ['nullable', 'numeric'],
            'lines.*.sgst_rate'       => ['nullable', 'numeric'],
            'lines.*.igst_rate'       => ['nullable', 'numeric'],
            'lines.*.cgst_amount'     => ['nullable', 'numeric'],
            'lines.*.sgst_amount'     => ['nullable', 'numeric'],
            'lines.*.igst_amount'     => ['nullable', 'numeric'],
            'lines.*.cess_rate'       => ['nullable', 'numeric'],
            'lines.*.cess_amount'     => ['nullable', 'numeric'],
            'lines.*.total_amount'    => ['required', 'numeric', 'min:0'],
            'lines.*.sort_order'      => ['nullable', 'integer'],
        ];
    }
}

