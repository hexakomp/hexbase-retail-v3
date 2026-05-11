<?php

namespace App\Http\Controllers\Api\V1\Reports;

use App\Http\Controllers\Controller;
use App\Services\GstReportService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GstReportController extends Controller
{
    public function __construct(private GstReportService $service) {}

    private function dates(Request $request): array
    {
        $request->validate([
            'from_date' => ['required', 'date'],
            'to_date'   => ['required', 'date', 'after_or_equal:from_date'],
        ]);
        return [$request->from_date, $request->to_date];
    }

    public function gstr1(Request $request): JsonResponse
    {
        [$from, $to] = $this->dates($request);
        $section = $request->string('section', 'b2b')->toString();

        $data = match ($section) {
            'b2c'              => $this->service->gstr1B2c($from, $to),
            'hsn-summary'      => $this->service->gstr1HsnSummary($from, $to),
            'document-summary' => $this->service->gstr1DocumentSummary($from, $to),
            'tax-liability'    => $this->service->gstr1TaxLiability($from, $to),
            default            => $this->service->gstr1B2b($from, $to),
        };

        return response()->json(['data' => $data, 'meta' => [], 'message' => 'OK']);
    }

    public function gstr3bSupport(Request $request): JsonResponse
    {
        [$from, $to] = $this->dates($request);
        return response()->json(['data' => $this->service->gstr3bSupport($from, $to), 'meta' => [], 'message' => 'OK']);
    }

    public function hsnSummary(Request $request): JsonResponse
    {
        [$from, $to] = $this->dates($request);
        return response()->json(['data' => $this->service->gstr1HsnSummary($from, $to), 'meta' => [], 'message' => 'OK']);
    }

    public function itcRegister(Request $request): JsonResponse
    {
        [$from, $to] = $this->dates($request);
        $vendorId = $request->integer('vendor_id') ?: null;
        return response()->json(['data' => $this->service->itcRegister($from, $to, $vendorId), 'meta' => [], 'message' => 'OK']);
    }

    public function salesTaxRegister(Request $request): JsonResponse
    {
        [$from, $to] = $this->dates($request);
        return response()->json(['data' => $this->service->salesTaxRegister($from, $to), 'meta' => [], 'message' => 'OK']);
    }

    public function purchaseTaxRegister(Request $request): JsonResponse
    {
        [$from, $to] = $this->dates($request);
        return response()->json(['data' => $this->service->purchaseTaxRegister($from, $to), 'meta' => [], 'message' => 'OK']);
    }
}
