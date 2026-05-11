<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\PaymentRequest;
use App\Models\Payment;
use App\Services\PaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    public function __construct(
        protected PaymentService $service,
    ) {}

    /**
     * GET /v1/payments
     */
    public function index(Request $request): JsonResponse
    {
        $query = Payment::with(['vendor:id,name'])
            ->search($request->input('search'))
            ->byStatus($request->input('status'))
            ->byPaymentMode($request->input('payment_mode'));

        if ($request->filled('vendor_id')) {
            $query->where('vendor_id', $request->integer('vendor_id'));
        }
        if ($request->filled('from_date')) {
            $query->where('payment_date', '>=', $request->input('from_date'));
        }
        if ($request->filled('to_date')) {
            $query->where('payment_date', '<=', $request->input('to_date'));
        }

        $payments = $query->latest('payment_date')->paginate(20);

        return response()->json([
            'data'    => $payments->items(),
            'meta'    => [
                'current_page' => $payments->currentPage(),
                'last_page'    => $payments->lastPage(),
                'per_page'     => $payments->perPage(),
                'total'        => $payments->total(),
            ],
            'message' => 'OK',
        ]);
    }

    /**
     * POST /v1/payments
     */
    public function store(PaymentRequest $request): JsonResponse
    {
        $payment = $this->service->createFromRequest($request->validated(), $request->user()->id);

        return response()->json(['data' => $payment, 'meta' => [], 'message' => 'Payment created.'], 201);
    }

    /**
     * GET /v1/payments/{payment}
     */
    public function show(Payment $payment): JsonResponse
    {
        $payment->load(['vendor', 'allocations.purchaseInvoice', 'createdBy:id,name']);

        return response()->json(['data' => $payment, 'meta' => [], 'message' => 'OK']);
    }

    /**
     * PUT /v1/payments/{payment}
     */
    public function update(PaymentRequest $request, Payment $payment): JsonResponse
    {
        $updated = $this->service->updateFromRequest($payment, $request->validated(), $request->user()->id);

        return response()->json(['data' => $updated, 'meta' => [], 'message' => 'Payment updated.']);
    }

    /**
     * DELETE /v1/payments/{payment}
     */
    public function destroy(Payment $payment): JsonResponse
    {
        if ($payment->status !== 'draft') {
            return response()->json(['message' => 'Only draft payments can be deleted.'], 422);
        }
        $payment->delete();

        return response()->json(['data' => null, 'meta' => [], 'message' => 'Payment deleted.']);
    }

    /**
     * POST /v1/payments/{payment}/post
     */
    public function post(Request $request, Payment $payment): JsonResponse
    {
        try {
            $posted = $this->service->post($payment, $request->user()->id);
        } catch (\RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json(['data' => $posted, 'meta' => [], 'message' => 'Payment posted.']);
    }

    /**
     * POST /v1/payments/{payment}/cancel
     */
    public function cancel(Request $request, Payment $payment): JsonResponse
    {
        $request->validate(['reason' => ['nullable', 'string', 'max:500']]);

        $cancelled = $this->service->cancel(
            $payment,
            $request->input('reason', ''),
            $request->user()->id
        );

        return response()->json(['data' => $cancelled, 'meta' => [], 'message' => 'Payment cancelled.']);
    }
}
