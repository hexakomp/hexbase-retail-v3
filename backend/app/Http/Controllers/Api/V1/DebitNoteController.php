<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\DebitNote;
use App\Services\DebitNoteService;
use App\Services\NumberingSequenceService;
use App\Services\PdfService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DebitNoteController extends Controller
{
    public function __construct(
        protected DebitNoteService         $service,
        protected PdfService               $pdfService,
        protected NumberingSequenceService $numbering,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $query = DebitNote::with(['vendor:id,name'])
            ->search($request->input('search'))
            ->byStatus($request->input('status'));

        if ($request->filled('vendor_id')) {
            $query->where('vendor_id', $request->integer('vendor_id'));
        }

        $notes = $query->latest('debit_note_date')->paginate(20);

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
            'debit_note_date'        => ['required', 'date'],
            'vendor_id'              => ['required', 'integer'],
            'purchase_invoice_id'    => ['nullable', 'integer'],
            'reason'                 => ['nullable', 'string', 'max:255'],
            'supply_type'            => ['nullable', 'in:intra,inter,import'],
            'lines'                  => ['required', 'array', 'min:1'],
            'lines.*.product_id'     => ['required', 'integer'],
            'lines.*.quantity'       => ['required', 'numeric', 'min:0.001'],
            'lines.*.unit_price'     => ['required', 'numeric', 'min:0'],
            'lines.*.gst_rate'       => ['nullable', 'integer'],
            'lines.*.discount_pct'   => ['nullable', 'numeric', 'min:0', 'max:100'],
        ]);

        $note = $this->service->create($data, $request->user()->id);

        return response()->json([
            'data'    => $note,
            'meta'    => [],
            'message' => 'Debit note created.',
        ], 201);
    }

    public function show(DebitNote $debitNote): JsonResponse
    {
        $debitNote->load(['vendor', 'lines.product', 'purchaseInvoice']);

        return response()->json([
            'data'    => $debitNote,
            'meta'    => [],
            'message' => 'OK',
        ]);
    }

    public function update(Request $request, DebitNote $debitNote): JsonResponse
    {
        $data = $request->validate([
            'debit_note_date'      => ['sometimes', 'date'],
            'reason'               => ['nullable', 'string', 'max:255'],
            'supply_type'          => ['nullable', 'in:intra,inter,import'],
            'lines'                => ['required', 'array', 'min:1'],
            'lines.*.product_id'   => ['required', 'integer'],
            'lines.*.quantity'     => ['required', 'numeric', 'min:0.001'],
            'lines.*.unit_price'   => ['required', 'numeric', 'min:0'],
            'lines.*.gst_rate'     => ['nullable', 'integer'],
            'lines.*.discount_pct' => ['nullable', 'numeric', 'min:0', 'max:100'],
        ]);

        $note = $this->service->update($debitNote, $data);

        return response()->json([
            'data'    => $note,
            'meta'    => [],
            'message' => 'Debit note updated.',
        ]);
    }

    public function post(Request $request, DebitNote $debitNote): JsonResponse
    {
        $note = $this->service->post($debitNote, $request->user()->id);

        return response()->json([
            'data'    => $note,
            'meta'    => [],
            'message' => 'Debit note posted.',
        ]);
    }

    public function cancel(Request $request, DebitNote $debitNote): JsonResponse
    {
        $note = $this->service->cancel($debitNote, $request->user()->id);

        return response()->json([
            'data'    => $note,
            'meta'    => [],
            'message' => 'Debit note cancelled.',
        ]);
    }

    public function pdf(DebitNote $debitNote): \Illuminate\Http\Response
    {
        $debitNote->load(['vendor', 'lines.product']);

        // Format the debit note number (apply prefix + padding) only for printing
        $formattedNumber = $this->numbering->format('debit_note', $debitNote->debit_note_number);
        $debitNote->debit_note_number = $formattedNumber;

        $pdf = $this->pdfService->generate('pdf.debit-note', ['note' => $debitNote]);

        return response($pdf, 200, [
            'Content-Type'        => 'application/pdf',
            'Content-Disposition' => 'inline; filename="' . $formattedNumber . '.pdf"',
        ]);
    }
}
