<?php

namespace App\Http\Controllers\Api\V1\Reports;

use App\Http\Controllers\Controller;
use App\Services\FinancialReportService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FinancialReportController extends Controller
{
    public function __construct(private FinancialReportService $service) {}

    private function dates(Request $request): array
    {
        $request->validate([
            'from_date' => ['required', 'date'],
            'to_date'   => ['required', 'date', 'after_or_equal:from_date'],
        ]);
        return [$request->from_date, $request->to_date];
    }

    private function asOfDate(Request $request): string
    {
        $request->validate(['as_of_date' => ['required', 'date']]);
        return $request->as_of_date;
    }

    public function trialBalance(Request $request): JsonResponse
    {
        $asOf = $this->asOfDate($request);
        return response()->json(['data' => $this->service->trialBalance($asOf), 'meta' => [], 'message' => 'OK']);
    }

    public function profitLoss(Request $request): JsonResponse
    {
        [$from, $to] = $this->dates($request);
        return response()->json(['data' => $this->service->profitLoss($from, $to), 'meta' => [], 'message' => 'OK']);
    }

    public function balanceSheet(Request $request): JsonResponse
    {
        $asOf = $this->asOfDate($request);
        return response()->json(['data' => $this->service->balanceSheet($asOf), 'meta' => [], 'message' => 'OK']);
    }

    public function dayBook(Request $request): JsonResponse
    {
        [$from, $to] = $this->dates($request);
        $type = $request->string('voucher_type')->toString() ?: null;
        return response()->json(['data' => $this->service->dayBook($from, $to, $type), 'meta' => [], 'message' => 'OK']);
    }

    public function cashBook(Request $request): JsonResponse
    {
        [$from, $to] = $this->dates($request);
        return response()->json(['data' => $this->service->cashBook($from, $to), 'meta' => [], 'message' => 'OK']);
    }

    public function salesRegister(Request $request): JsonResponse
    {
        [$from, $to] = $this->dates($request);
        $customerId = $request->integer('customer_id') ?: null;
        return response()->json(['data' => $this->service->salesRegister($from, $to, $customerId), 'meta' => [], 'message' => 'OK']);
    }

    public function purchaseRegister(Request $request): JsonResponse
    {
        [$from, $to] = $this->dates($request);
        $vendorId = $request->integer('vendor_id') ?: null;
        return response()->json(['data' => $this->service->purchaseRegister($from, $to, $vendorId), 'meta' => [], 'message' => 'OK']);
    }

    public function cashFlow(Request $request): JsonResponse
    {
        [$from, $to] = $this->dates($request);
        return response()->json(['data' => $this->service->cashFlow($from, $to), 'meta' => [], 'message' => 'OK']);
    }

    public function ledger(Request $request, int $account_id): JsonResponse
    {
        [$from, $to] = $this->dates($request);
        return response()->json(['data' => $this->service->ledger($account_id, $from, $to), 'meta' => [], 'message' => 'OK']);
    }

    public function receivablesAgeing(Request $request): JsonResponse
    {
        $asOf = $this->asOfDate($request);
        return response()->json(['data' => $this->service->receivablesAgeing($asOf), 'meta' => [], 'message' => 'OK']);
    }

    public function payablesAgeing(Request $request): JsonResponse
    {
        $asOf = $this->asOfDate($request);
        return response()->json(['data' => $this->service->payablesAgeing($asOf), 'meta' => [], 'message' => 'OK']);
    }
}

