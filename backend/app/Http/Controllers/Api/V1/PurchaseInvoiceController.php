<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\PurchaseInvoiceRequest;
use App\Models\PurchaseInvoice;
use App\Services\PurchaseInvoiceService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

/**
 * PurchaseInvoiceController — REST controller for purchase invoices.
 *
 * Routes (registered in routes/api.php):
 *   GET    /v1/purchase-invoices
 *   POST   /v1/purchase-invoices
 *   GET    /v1/purchase-invoices/{purchaseInvoice}
 *   PUT    /v1/purchase-invoices/{purchaseInvoice}
 *   POST   /v1/purchase-invoices/{purchaseInvoice}/post
 *   POST   /v1/purchase-invoices/{purchaseInvoice}/cancel
 *   POST   /v1/purchase-invoices/{purchaseInvoice}/attach
 */
class PurchaseInvoiceController extends Controller
{
    public function __construct(
        protected PurchaseInvoiceService $service,
    ) {}

    /**
     * GET /v1/purchase-invoices
     */
    public function index(Request $request): JsonResponse
    {
        $query = PurchaseInvoice::with(['vendor:id,name,gstin'])
            ->search($request->input('search'))
            ->byStatus($request->input('status'));

        if ($request->filled('vendor_id')) {
            $query->where('vendor_id', $request->integer('vendor_id'));
        }
        if ($request->filled('from_date')) {
            $query->where('invoice_date', '>=', $request->input('from_date'));
        }
        if ($request->filled('to_date')) {
            $query->where('invoice_date', '<=', $request->input('to_date'));
        }

        $invoices = $query->latest('invoice_date')->paginate(20);

        return response()->json([
            'data'    => $invoices->items(),
            'meta'    => [
                'current_page' => $invoices->currentPage(),
                'last_page'    => $invoices->lastPage(),
                'per_page'     => $invoices->perPage(),
                'total'        => $invoices->total(),
            ],
            'message' => 'OK',
        ]);
    }

    /**
     * POST /v1/purchase-invoices
     */
    public function store(PurchaseInvoiceRequest $request): JsonResponse
    {
        $invoice = $this->service->createFromRequest($request->validated(), $request->user()->id);

        return response()->json(['data' => $invoice, 'meta' => [], 'message' => 'Purchase invoice created.'], 201);
    }

    /**
     * GET /v1/purchase-invoices/{purchaseInvoice}
     */
    public function show(PurchaseInvoice $purchaseInvoice): JsonResponse
    {
        $purchaseInvoice->load(['vendor', 'lines.product', 'createdBy:id,name']);

        return response()->json(['data' => $purchaseInvoice, 'meta' => [], 'message' => 'OK']);
    }

    /**
     * PUT /v1/purchase-invoices/{purchaseInvoice}
     */
    public function update(PurchaseInvoiceRequest $request, PurchaseInvoice $purchaseInvoice): JsonResponse
    {
        $updated = $this->service->updateFromRequest($purchaseInvoice, $request->validated(), $request->user()->id);

        return response()->json(['data' => $updated, 'meta' => [], 'message' => 'Purchase invoice updated.']);
    }

    /**
     * DELETE /v1/purchase-invoices/{purchaseInvoice}  — soft-delete draft only
     */
    public function destroy(PurchaseInvoice $purchaseInvoice): JsonResponse
    {
        if ($purchaseInvoice->status !== 'draft') {
            return response()->json(['message' => 'Only draft purchase invoices can be deleted.'], 422);
        }
        $purchaseInvoice->delete();

        return response()->json(['data' => null, 'meta' => [], 'message' => 'Purchase invoice deleted.']);
    }

    /**
     * POST /v1/purchase-invoices/{purchaseInvoice}/post
     */
    public function post(Request $request, PurchaseInvoice $purchaseInvoice): JsonResponse
    {
        $posted = $this->service->post($purchaseInvoice, $request->user()->id);

        return response()->json(['data' => $posted, 'meta' => [], 'message' => 'Purchase invoice posted.']);
    }

    /**
     * POST /v1/purchase-invoices/{purchaseInvoice}/cancel
     */
    public function cancel(Request $request, PurchaseInvoice $purchaseInvoice): JsonResponse
    {
        $request->validate(['reason' => ['nullable', 'string', 'max:500']]);

        try {
            $cancelled = $this->service->cancel(
                $purchaseInvoice,
                $request->input('reason', ''),
                $request->user()->id
            );
        } catch (\RuntimeException $e) {
            $code = $e->getCode() === 409 ? 409 : 422;

            return response()->json(['message' => $e->getMessage()], $code);
        }

        return response()->json(['data' => $cancelled, 'meta' => [], 'message' => 'Purchase invoice cancelled.']);
    }

    /**
     * POST /v1/purchase-invoices/{purchaseInvoice}/attach
     * Upload scanned invoice PDF/image (max 10 MB).
     */
    public function attach(Request $request, PurchaseInvoice $purchaseInvoice): JsonResponse
    {
        $request->validate([
            'file' => ['required', 'file', 'mimes:pdf,jpg,jpeg,png', 'max:10240'],
        ]);

        $path = $request->file('file')->store(
            "purchase-attachments/{$purchaseInvoice->id}",
            'local'
        );

        $updated = $this->service->storeAttachment($purchaseInvoice, $path);

        return response()->json([
            'data'    => ['attachment_path' => $updated->attachment_path],
            'meta'    => [],
            'message' => 'Attachment uploaded.',
        ]);
    }
}
