<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\CreditNote;
use App\Services\CreditNoteService;
use App\Services\NumberingSequenceService;
use App\Services\PdfService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CreditNoteController extends Controller
{
    public function __construct(
        protected CreditNoteService        $service,
        protected PdfService               $pdfService,
        protected NumberingSequenceService $numbering,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $query = CreditNote::with(['customer:id,name'])
            ->search($request->input('search'))
            ->byStatus($request->input('status'));

        if ($request->filled('customer_id')) {
            $query->where('customer_id', $request->integer('customer_id'));
        }

        $notes = $query->latest('credit_note_date')->paginate(20);

        return response()->json([
            'data'    => $notes->items(),
            'meta'    => [
                'current_page' => $notes->currentPage(),
                'last_page'    => $notes->lastPage(),
                'per_page'     => $notes->perPage(),
                'total'        => $notes->total(),
            ],
            'message' => 'OK',
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'credit_note_date'   => ['required', 'date'],
            'customer_id'        => ['required', 'integer'],
            'sales_invoice_id'   => ['nullable', 'integer'],
            'reason'             => ['nullable', 'string', 'max:255'],
            'supply_type'        => ['nullable', 'in:intra,inter,export'],
            'place_of_supply'    => ['nullable', 'string', 'max:2'],
            'lines'              => ['required', 'array', 'min:1'],
            'lines.*.product_id' => ['required', 'integer'],
            'lines.*.quantity'   => ['required', 'numeric', 'min:0.001'],
            'lines.*.unit_price' => ['required', 'numeric', 'min:0'],
            'lines.*.gst_rate'   => ['nullable', 'integer'],
            'lines.*.discount_pct' => ['nullable', 'numeric', 'min:0', 'max:100'],
        ]);

        $note = $this->service->create($data, $request->user()->id);

        return response()->json([
            'data'    => $note,
            'meta'    => [],
            'message' => 'Credit note created.',
        ], 201);
    }

    public function show(CreditNote $creditNote): JsonResponse
    {
        $creditNote->load(['customer', 'lines.product', 'salesInvoice']);

        return response()->json([
            'data'    => $creditNote,
            'meta'    => [],
            'message' => 'OK',
        ]);
    }

    public function update(Request $request, CreditNote $creditNote): JsonResponse
    {
        $data = $request->validate([
            'credit_note_date'   => ['sometimes', 'date'],
            'reason'             => ['nullable', 'string', 'max:255'],
            'supply_type'        => ['nullable', 'in:intra,inter,export'],
            'lines'              => ['required', 'array', 'min:1'],
            'lines.*.product_id' => ['required', 'integer'],
            'lines.*.quantity'   => ['required', 'numeric', 'min:0.001'],
            'lines.*.unit_price' => ['required', 'numeric', 'min:0'],
            'lines.*.gst_rate'   => ['nullable', 'integer'],
            'lines.*.discount_pct' => ['nullable', 'numeric', 'min:0', 'max:100'],
        ]);

        $note = $this->service->update($creditNote, $data);

        return response()->json([
            'data'    => $note,
            'meta'    => [],
            'message' => 'Credit note updated.',
        ]);
    }

    public function post(Request $request, CreditNote $creditNote): JsonResponse
    {
        $note = $this->service->post($creditNote, $request->user()->id);

        return response()->json([
            'data'    => $note,
            'meta'    => [],
            'message' => 'Credit note posted.',
        ]);
    }

    public function cancel(Request $request, CreditNote $creditNote): JsonResponse
    {
        $note = $this->service->cancel($creditNote, $request->user()->id);

        return response()->json([
            'data'    => $note,
            'meta'    => [],
            'message' => 'Credit note cancelled.',
        ]);
    }

    public function pdf(CreditNote $creditNote): \Illuminate\Http\Response
    {
        $creditNote->load(['customer', 'lines.product']);

        // Format the credit note number (apply prefix + padding) only for printing
        $formattedNumber = $this->numbering->format('credit_note', $creditNote->credit_note_number);
        $creditNote->credit_note_number = $formattedNumber;

        $pdf = $this->pdfService->generate('pdf.credit-note', ['note' => $creditNote]);

        return response($pdf, 200, [
            'Content-Type'        => 'application/pdf',
            'Content-Disposition' => 'inline; filename="' . $formattedNumber . '.pdf"',
        ]);
    }
}
