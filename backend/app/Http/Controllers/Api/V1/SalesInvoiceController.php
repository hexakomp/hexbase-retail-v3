<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\SalesInvoiceRequest;
use App\Models\SalesInvoice;
use App\Services\NumberingSequenceService;
use App\Services\PdfService;
use App\Services\SalesInvoiceService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * SalesInvoiceController — REST controller for sales invoices.
 *
 * Routes (registered in routes/api.php):
 *   GET    /v1/invoices
 *   POST   /v1/invoices/calculate   (T046 — stateless preview)
 *   POST   /v1/invoices
 *   GET    /v1/invoices/{invoice}
 *   PUT    /v1/invoices/{invoice}
 *   POST   /v1/invoices/{invoice}/post
 *   POST   /v1/invoices/{invoice}/cancel
 *   GET    /v1/invoices/{invoice}/pdf
 */
class SalesInvoiceController extends Controller
{
    public function __construct(
        protected SalesInvoiceService      $service,
        protected PdfService               $pdfService,
        protected NumberingSequenceService $numbering,
    ) {}

    // ── Collection ─────────────────────────────────────────────────────────

    /**
     * GET /v1/invoices
     * Query params: search, customer_id, from_date, to_date, status, page
     */
    public function index(Request $request): JsonResponse
    {
        $query = SalesInvoice::with(['customer:id,name,gstin'])
            ->search($request->input('search'))
            ->byStatus($request->input('status'));

        if ($request->filled('customer_id')) {
            $query->where('customer_id', $request->integer('customer_id'));
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

    // ── T046: Stateless tax preview ────────────────────────────────────────

    /**
     * POST /v1/invoices/calculate
     * Returns real-time GST breakdown without saving.
     */
    public function calculate(Request $request): JsonResponse
    {
        $data = $request->validate([
            'customer_id'              => ['required', 'integer'],
            'place_of_supply'          => ['required', 'string', 'max:2'],
            'invoice_type'             => ['required', 'in:b2b,b2c,export'],
            'lines'                    => ['required', 'array', 'min:1'],
            'lines.*.product_id'       => ['required', 'integer'],
            'lines.*.quantity'         => ['required', 'numeric', 'gt:0'],
            'lines.*.rate'             => ['required', 'numeric', 'min:0'],
            'lines.*.discount_percent' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'lines.*.gst_rate'         => ['required', 'numeric', 'min:0'],
            'lines.*.cess_rate'        => ['nullable', 'numeric', 'min:0'],
        ]);

        $result = $this->service->preview($data);

        return response()->json(['data' => $result, 'meta' => [], 'message' => 'OK']);
    }

    // ── Single resource ─────────────────────────────────────────────────────

    /**
     * POST /v1/invoices
     */
    public function store(SalesInvoiceRequest $request): JsonResponse
    {
        $invoice = $this->service->createFromRequest($request->validated(), $request->user()->id);

        return response()->json(['data' => $invoice, 'meta' => [], 'message' => 'Invoice created.'], 201);
    }

    /**
     * GET /v1/invoices/{invoice}
     */
    public function show(SalesInvoice $invoice): JsonResponse
    {
        $invoice->load(['customer', 'lines.product', 'createdBy:id,name']);

        return response()->json(['data' => $invoice, 'meta' => [], 'message' => 'OK']);
    }

    /**
     * PUT /v1/invoices/{invoice}
     */
    public function update(SalesInvoiceRequest $request, SalesInvoice $invoice): JsonResponse
    {
        $updated = $this->service->updateFromRequest($invoice, $request->validated(), $request->user()->id);

        return response()->json(['data' => $updated, 'meta' => [], 'message' => 'Invoice updated.']);
    }

    /**
     * DELETE /v1/invoices/{invoice}  — soft-delete (draft only)
     */
    public function destroy(SalesInvoice $invoice): JsonResponse
    {
        if ($invoice->status !== 'draft') {
            return response()->json(['data' => null, 'meta' => [], 'message' => 'Only draft invoices can be deleted.'], 422);
        }
        $invoice->delete();

        return response()->json(['data' => null, 'meta' => [], 'message' => 'Invoice deleted.']);
    }

    // ── Actions ─────────────────────────────────────────────────────────────

    /**
     * POST /v1/invoices/{invoice}/post
     */
    public function post(Request $request, SalesInvoice $invoice): JsonResponse
    {
        $posted = $this->service->post($invoice, $request->user()->id);

        return response()->json(['data' => $posted, 'meta' => [], 'message' => 'Invoice posted.']);
    }

    /**
     * POST /v1/invoices/{invoice}/cancel
     */
    public function cancel(Request $request, SalesInvoice $invoice): JsonResponse
    {
        $request->validate(['reason' => ['nullable', 'string', 'max:500']]);

        $cancelled = $this->service->cancel($invoice, $request->input('reason', ''), $request->user()->id);

        return response()->json(['data' => $cancelled, 'meta' => [], 'message' => 'Invoice cancelled.']);
    }

    /**
     * GET /v1/invoices/{invoice}/pdf
     * Synchronous PDF generation (≤10 s per SC-011).
     */
    public function pdf(SalesInvoice $invoice): \Symfony\Component\HttpFoundation\StreamedResponse
    {
        $invoice->load(['customer', 'lines.product']);

        $companySettings = \Illuminate\Support\Facades\DB::connection('tenant')
            ->table('company_settings')
            ->first();

        // Format the invoice number (apply prefix + padding) only for printing
        $formattedNumber = $this->numbering->format('sales_invoice', $invoice->invoice_number);
        $invoice->invoice_number = $formattedNumber;

        return $this->pdfService->download(
            'pdf.sales-invoice',
            compact('invoice', 'companySettings'),
            $formattedNumber . '.pdf'
        );
    }
}
