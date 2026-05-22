<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\DeliveryChallan;
use App\Models\DeliveryChallanLine;
use App\Services\NumberingSequenceService;
use App\Services\PdfService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;

class DeliveryChallanController extends Controller
{
    public function __construct(
        protected NumberingSequenceService $numbering,
        protected PdfService               $pdf,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $query = DeliveryChallan::with(['customer:id,name'])
            ->search($request->input('search'))
            ->byStatus($request->input('status'));

        if ($customerId = $request->input('customer_id')) {
            $query->where('customer_id', $customerId);
        }

        $challans = $query->latest('dc_date')->paginate(20);

        return response()->json([
            'data'    => $challans->items(),
            'meta'    => [
                'current_page' => $challans->currentPage(),
                'last_page'    => $challans->lastPage(),
                'per_page'     => $challans->perPage(),
                'total'        => $challans->total(),
            ],
            'message' => 'OK',
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'dc_date'           => ['required', 'date'],
            'customer_id'       => ['required', 'integer'],
            'sales_invoice_id'  => ['nullable', 'integer'],
            'vehicle_number'    => ['nullable', 'string'],
            'transporter_name'  => ['nullable', 'string'],
            'dispatch_through'  => ['nullable', 'string'],
            'destination'       => ['nullable', 'string'],
            'notes'             => ['nullable', 'string'],
            'lines'             => ['required', 'array', 'min:1'],
            'lines.*.product_id'=> ['required', 'integer'],
            'lines.*.quantity'  => ['required', 'numeric', 'min:0.001'],
            'lines.*.unit_price'=> ['nullable', 'numeric', 'min:0'],
        ]);

        $challan = DB::connection('tenant')->transaction(function () use ($data, $request) {
            $dc = DeliveryChallan::create([
                'dc_number'         => $this->numbering->next('delivery_challan'),
                'dc_date'           => $data['dc_date'],
                'customer_id'       => $data['customer_id'],
                'sales_invoice_id'  => $data['sales_invoice_id'] ?? null,
                'vehicle_number'    => $data['vehicle_number'] ?? null,
                'transporter_name'  => $data['transporter_name'] ?? null,
                'dispatch_through'  => $data['dispatch_through'] ?? null,
                'destination'       => $data['destination'] ?? null,
                'notes'             => $data['notes'] ?? null,
                'status'            => 'draft',
                'created_by'        => $request->user()->id,
                'subtotal'          => 0,
                'total_amount'      => 0,
            ]);

            $totals = $this->saveLines($dc, $data['lines']);
            $dc->update($totals);

            return $dc->load(['customer', 'lines.product']);
        });

        return response()->json(['data' => $challan, 'meta' => [], 'message' => 'Delivery challan created.'], 201);
    }

    public function show(DeliveryChallan $deliveryChallan): JsonResponse
    {
        $deliveryChallan->load(['customer', 'salesInvoice', 'lines.product']);
        return response()->json(['data' => $deliveryChallan, 'meta' => [], 'message' => 'OK']);
    }

    public function update(Request $request, DeliveryChallan $deliveryChallan): JsonResponse
    {
        if ($deliveryChallan->status !== 'draft') {
            return response()->json(['message' => 'Only draft challans can be edited.'], 422);
        }

        $data = $request->validate([
            'dc_date'           => ['sometimes', 'date'],
            'vehicle_number'    => ['nullable', 'string'],
            'transporter_name'  => ['nullable', 'string'],
            'dispatch_through'  => ['nullable', 'string'],
            'destination'       => ['nullable', 'string'],
            'notes'             => ['nullable', 'string'],
            'lines'             => ['required', 'array', 'min:1'],
            'lines.*.product_id'=> ['required', 'integer'],
            'lines.*.quantity'  => ['required', 'numeric', 'min:0.001'],
            'lines.*.unit_price'=> ['nullable', 'numeric', 'min:0'],
        ]);

        $challan = DB::connection('tenant')->transaction(function () use ($deliveryChallan, $data) {
            $deliveryChallan->lines()->delete();
            $deliveryChallan->update([
                'dc_date'          => $data['dc_date'] ?? $deliveryChallan->dc_date,
                'vehicle_number'   => $data['vehicle_number'] ?? $deliveryChallan->vehicle_number,
                'transporter_name' => $data['transporter_name'] ?? $deliveryChallan->transporter_name,
                'dispatch_through' => $data['dispatch_through'] ?? $deliveryChallan->dispatch_through,
                'destination'      => $data['destination'] ?? $deliveryChallan->destination,
                'notes'            => $data['notes'] ?? $deliveryChallan->notes,
            ]);
            $totals = $this->saveLines($deliveryChallan, $data['lines']);
            $deliveryChallan->update($totals);
            return $deliveryChallan->fresh(['customer', 'lines.product']);
        });

        return response()->json(['data' => $challan, 'meta' => [], 'message' => 'Delivery challan updated.']);
    }

    public function dispatch(DeliveryChallan $deliveryChallan): JsonResponse
    {
        if ($deliveryChallan->status !== 'draft') {
            return response()->json(['message' => 'Only draft challans can be dispatched.'], 422);
        }

        $deliveryChallan->update(['status' => 'dispatched']);

        return response()->json(['data' => $deliveryChallan->fresh(), 'meta' => [], 'message' => 'Delivery challan dispatched.']);
    }

    public function cancel(DeliveryChallan $deliveryChallan): JsonResponse
    {
        $deliveryChallan->update(['status' => 'cancelled']);
        return response()->json(['data' => $deliveryChallan->fresh(), 'meta' => [], 'message' => 'Delivery challan cancelled.']);
    }

    public function pdf(DeliveryChallan $deliveryChallan): Response
    {
        $deliveryChallan->load(['customer', 'lines.product']);

        // Format the DC number (apply prefix + padding) only for printing
        $formattedNumber = $this->numbering->format('delivery_challan', $deliveryChallan->dc_number);
        $deliveryChallan->dc_number = $formattedNumber;

        $bytes = $this->pdf->generate('pdf.delivery-challan', ['dc' => $deliveryChallan]);

        return response($bytes, 200, [
            'Content-Type'        => 'application/pdf',
            'Content-Disposition' => 'inline; filename="' . $formattedNumber . '.pdf"',
        ]);
    }

    // ── Private ──────────────────────────────────────────────────────────────

    private function saveLines(DeliveryChallan $dc, array $lines): array
    {
        $subtotal = 0;

        foreach ($lines as $i => $line) {
            $unitPrice = (float) ($line['unit_price'] ?? 0);
            $lineTotal = round($line['quantity'] * $unitPrice, 2);

            DeliveryChallanLine::create([
                'delivery_challan_id' => $dc->id,
                'product_id'          => $line['product_id'],
                'description'         => $line['description'] ?? null,
                'quantity'            => $line['quantity'],
                'unit'                => $line['unit'] ?? 'PCS',
                'unit_price'          => $unitPrice,
                'line_total'          => $lineTotal,
                'sort_order'          => $i,
            ]);

            $subtotal += $lineTotal;
        }

        return ['subtotal' => $subtotal, 'total_amount' => $subtotal];
    }
}
