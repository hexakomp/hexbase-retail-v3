<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\ReceiptRequest;
use App\Models\Receipt;
use App\Services\ReceiptService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReceiptController extends Controller
{
    public function __construct(
        protected ReceiptService $service,
    ) {}

    /**
     * GET /v1/receipts
     */
    public function index(Request $request): JsonResponse
    {
        $query = Receipt::with(['customer:id,name'])
            ->search($request->input('search'))
            ->byStatus($request->input('status'))
            ->byPaymentMode($request->input('payment_mode'));

        if ($request->filled('customer_id')) {
            $query->where('customer_id', $request->integer('customer_id'));
        }
        if ($request->filled('from_date')) {
            $query->where('receipt_date', '>=', $request->input('from_date'));
        }
        if ($request->filled('to_date')) {
            $query->where('receipt_date', '<=', $request->input('to_date'));
        }

        $receipts = $query->latest('receipt_date')->paginate(20);

        return response()->json([
            'data'    => $receipts->items(),
            'meta'    => [
                'current_page' => $receipts->currentPage(),
                'last_page'    => $receipts->lastPage(),
                'per_page'     => $receipts->perPage(),
                'total'        => $receipts->total(),
            ],
            'message' => 'OK',
        ]);
    }

    /**
     * POST /v1/receipts
     */
    public function store(ReceiptRequest $request): JsonResponse
    {
        $receipt = $this->service->createFromRequest($request->validated(), $request->user()->id);

        return response()->json(['data' => $receipt, 'meta' => [], 'message' => 'Receipt created.'], 201);
    }

    /**
     * GET /v1/receipts/{receipt}
     */
    public function show(Receipt $receipt): JsonResponse
    {
        $receipt->load(['customer', 'allocations.salesInvoice', 'createdBy:id,name']);

        return response()->json(['data' => $receipt, 'meta' => [], 'message' => 'OK']);
    }

    /**
     * PUT /v1/receipts/{receipt}
     */
    public function update(ReceiptRequest $request, Receipt $receipt): JsonResponse
    {
        $updated = $this->service->updateFromRequest($receipt, $request->validated(), $request->user()->id);

        return response()->json(['data' => $updated, 'meta' => [], 'message' => 'Receipt updated.']);
    }

    /**
     * DELETE /v1/receipts/{receipt}
     */
    public function destroy(Receipt $receipt): JsonResponse
    {
        if ($receipt->status !== 'draft') {
            return response()->json(['message' => 'Only draft receipts can be deleted.'], 422);
        }
        $receipt->delete();

        return response()->json(['data' => null, 'meta' => [], 'message' => 'Receipt deleted.']);
    }

    /**
     * POST /v1/receipts/{receipt}/post
     */
    public function post(Request $request, Receipt $receipt): JsonResponse
    {
        try {
            $posted = $this->service->post($receipt, $request->user()->id);
        } catch (\RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json(['data' => $posted, 'meta' => [], 'message' => 'Receipt posted.']);
    }

    /**
     * POST /v1/receipts/{receipt}/cancel
     */
    public function cancel(Request $request, Receipt $receipt): JsonResponse
    {
        $request->validate(['reason' => ['nullable', 'string', 'max:500']]);

        $cancelled = $this->service->cancel(
            $receipt,
            $request->input('reason', ''),
            $request->user()->id
        );

        return response()->json(['data' => $cancelled, 'meta' => [], 'message' => 'Receipt cancelled.']);
    }
}
