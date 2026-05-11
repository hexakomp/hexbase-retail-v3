<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\PurchaseOrder;
use App\Models\PurchaseOrderLine;
use App\Services\NumberingSequenceService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PurchaseOrderController extends Controller
{
    public function __construct(
        protected NumberingSequenceService $numbering,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $query = PurchaseOrder::with(['vendor:id,name'])
            ->search($request->input('search'))
            ->byStatus($request->input('status'));

        $orders = $query->latest('po_date')->paginate(20);

        return response()->json([
            'data'    => $orders->items(),
            'meta'    => [
                'current_page' => $orders->currentPage(),
                'last_page'    => $orders->lastPage(),
                'per_page'     => $orders->perPage(),
                'total'        => $orders->total(),
            ],
            'message' => 'OK',
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'po_date'                => ['required', 'date'],
            'vendor_id'              => ['required', 'integer'],
            'expected_delivery_date' => ['nullable', 'date'],
            'notes'                  => ['nullable', 'string'],
            'supply_type'            => ['nullable', 'in:intra,inter,import'],
            'lines'                  => ['required', 'array', 'min:1'],
            'lines.*.product_id'     => ['required', 'integer'],
            'lines.*.quantity'       => ['required', 'numeric', 'min:0.001'],
            'lines.*.unit_price'     => ['required', 'numeric', 'min:0'],
            'lines.*.gst_rate'       => ['nullable', 'integer'],
        ]);

        $order = DB::connection('tenant')->transaction(function () use ($data, $request) {
            $po = PurchaseOrder::create([
                'po_number'              => $this->numbering->next('purchase_order'),
                'po_date'               => $data['po_date'],
                'vendor_id'             => $data['vendor_id'],
                'expected_delivery_date'=> $data['expected_delivery_date'] ?? null,
                'notes'                 => $data['notes'] ?? null,
                'status'                => 'draft',
                'created_by'            => $request->user()->id,
                'subtotal'              => 0,
                'cgst_amount'           => 0,
                'sgst_amount'           => 0,
                'igst_amount'           => 0,
                'tax_amount'            => 0,
                'total_amount'          => 0,
            ]);

            $totals = $this->saveLines($po, $data['lines'], $data['supply_type'] ?? 'intra');
            $po->update($totals);

            return $po->load(['vendor', 'lines.product']);
        });

        return response()->json(['data' => $order, 'meta' => [], 'message' => 'Purchase order created.'], 201);
    }

    public function show(PurchaseOrder $purchaseOrder): JsonResponse
    {
        $purchaseOrder->load(['vendor', 'lines.product']);
        return response()->json(['data' => $purchaseOrder, 'meta' => [], 'message' => 'OK']);
    }

    public function update(Request $request, PurchaseOrder $purchaseOrder): JsonResponse
    {
        if ($purchaseOrder->status !== 'draft') {
            return response()->json(['message' => 'Only draft POs can be edited.'], 422);
        }

        $data = $request->validate([
            'po_date'                => ['sometimes', 'date'],
            'expected_delivery_date' => ['nullable', 'date'],
            'notes'                  => ['nullable', 'string'],
            'supply_type'            => ['nullable', 'in:intra,inter,import'],
            'lines'                  => ['required', 'array', 'min:1'],
            'lines.*.product_id'     => ['required', 'integer'],
            'lines.*.quantity'       => ['required', 'numeric', 'min:0.001'],
            'lines.*.unit_price'     => ['required', 'numeric', 'min:0'],
            'lines.*.gst_rate'       => ['nullable', 'integer'],
        ]);

        $order = DB::connection('tenant')->transaction(function () use ($purchaseOrder, $data) {
            $purchaseOrder->lines()->delete();
            $purchaseOrder->update([
                'po_date'               => $data['po_date'] ?? $purchaseOrder->po_date,
                'expected_delivery_date'=> $data['expected_delivery_date'] ?? $purchaseOrder->expected_delivery_date,
                'notes'                 => $data['notes'] ?? $purchaseOrder->notes,
            ]);
            $totals = $this->saveLines($purchaseOrder, $data['lines'], $data['supply_type'] ?? 'intra');
            $purchaseOrder->update($totals);
            return $purchaseOrder->fresh(['vendor', 'lines.product']);
        });

        return response()->json(['data' => $order, 'meta' => [], 'message' => 'Purchase order updated.']);
    }

    public function cancel(PurchaseOrder $purchaseOrder): JsonResponse
    {
        $purchaseOrder->update(['status' => 'cancelled']);
        return response()->json(['data' => $purchaseOrder->fresh(), 'meta' => [], 'message' => 'Purchase order cancelled.']);
    }

    // ── Private ──────────────────────────────────────────────────────────────

    private function saveLines(PurchaseOrder $po, array $lines, string $supplyType): array
    {
        $subtotal = 0;
        $cgstTotal = 0;
        $sgstTotal = 0;
        $igstTotal = 0;
        $isIntra   = strtolower($supplyType) === 'intra';

        foreach ($lines as $i => $line) {
            $taxable  = round($line['quantity'] * $line['unit_price'], 2);
            $gstRate  = (int) ($line['gst_rate'] ?? 0);
            $cgstRate = $isIntra ? $gstRate / 2 : 0;
            $sgstRate = $isIntra ? $gstRate / 2 : 0;
            $igstRate = $isIntra ? 0 : $gstRate;
            $cgstAmt  = round($taxable * $cgstRate / 100, 2);
            $sgstAmt  = round($taxable * $sgstRate / 100, 2);
            $igstAmt  = round($taxable * $igstRate / 100, 2);
            $taxAmt   = $cgstAmt + $sgstAmt + $igstAmt;

            PurchaseOrderLine::create([
                'purchase_order_id' => $po->id,
                'product_id'        => $line['product_id'],
                'description'       => $line['description'] ?? null,
                'hsn_sac'           => $line['hsn_sac'] ?? null,
                'quantity'          => $line['quantity'],
                'unit'              => $line['unit'] ?? 'PCS',
                'unit_price'        => $line['unit_price'],
                'discount_pct'      => 0,
                'discount_amount'   => 0,
                'taxable_amount'    => $taxable,
                'gst_rate'          => $gstRate,
                'cgst_rate'         => $cgstRate,
                'cgst_amount'       => $cgstAmt,
                'sgst_rate'         => $sgstRate,
                'sgst_amount'       => $sgstAmt,
                'igst_rate'         => $igstRate,
                'igst_amount'       => $igstAmt,
                'tax_amount'        => $taxAmt,
                'line_total'        => $taxable + $taxAmt,
                'sort_order'        => $i,
            ]);

            $subtotal  += $taxable;
            $cgstTotal += $cgstAmt;
            $sgstTotal += $sgstAmt;
            $igstTotal += $igstAmt;
        }

        $taxTotal = $cgstTotal + $sgstTotal + $igstTotal;

        return [
            'subtotal'    => $subtotal,
            'cgst_amount' => $cgstTotal,
            'sgst_amount' => $sgstTotal,
            'igst_amount' => $igstTotal,
            'tax_amount'  => $taxTotal,
            'total_amount'=> $subtotal + $taxTotal,
        ];
    }
}
