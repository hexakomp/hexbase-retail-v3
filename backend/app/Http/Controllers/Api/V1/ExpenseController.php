<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use App\Services\AccountingEngine;
use App\Services\NumberingSequenceService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ExpenseController extends Controller
{
    public function __construct(
        protected NumberingSequenceService $numbering,
        protected AccountingEngine         $accounting,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $query = Expense::with(['vendor:id,name', 'customer:id,name'])
            ->search($request->input('search'))
            ->byStatus($request->input('status'));

        if ($cat = $request->input('category')) {
            $query->where('category', $cat);
        }

        $expenses = $query->latest('expense_date')->paginate(20);

        return response()->json([
            'data'    => $expenses->items(),
            'meta'    => [
                'current_page' => $expenses->currentPage(),
                'last_page'    => $expenses->lastPage(),
                'per_page'     => $expenses->perPage(),
                'total'        => $expenses->total(),
            ],
            'message' => 'OK',
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'expense_date'   => ['required', 'date'],
            'category'       => ['required', 'string', 'max:100'],
            'description'    => ['required', 'string'],
            'vendor_id'      => ['nullable', 'integer'],
            'bank_account_id'=> ['nullable', 'integer'],
            'payment_mode'   => ['required', 'in:cash,bank,upi,cheque'],
            'amount'         => ['required', 'numeric', 'min:0'],
            'gst_amount'     => ['nullable', 'numeric', 'min:0'],
            'is_billable'    => ['nullable', 'boolean'],
            'customer_id'    => ['nullable', 'integer'],
            'reference'      => ['nullable', 'string'],
        ]);

        $expense = Expense::create([
            'expense_number' => $this->numbering->next('expense'),
            'expense_date'   => $data['expense_date'],
            'category'       => $data['category'],
            'description'    => $data['description'],
            'vendor_id'      => $data['vendor_id'] ?? null,
            'bank_account_id'=> $data['bank_account_id'] ?? null,
            'payment_mode'   => $data['payment_mode'],
            'amount'         => $data['amount'],
            'gst_amount'     => $data['gst_amount'] ?? 0,
            'total_amount'   => $data['amount'] + ($data['gst_amount'] ?? 0),
            'is_billable'    => $data['is_billable'] ?? false,
            'customer_id'    => $data['customer_id'] ?? null,
            'reference'      => $data['reference'] ?? null,
            'status'         => 'draft',
            'created_by'     => $request->user()->id,
        ]);

        return response()->json(['data' => $expense->fresh(), 'meta' => [], 'message' => 'Expense created.'], 201);
    }

    public function show(Expense $expense): JsonResponse
    {
        $expense->load(['vendor', 'customer', 'bankAccount']);
        return response()->json(['data' => $expense, 'meta' => [], 'message' => 'OK']);
    }

    public function post(Request $request, Expense $expense): JsonResponse
    {
        if ($expense->status !== 'draft') {
            return response()->json(['message' => 'Only draft expenses can be posted.'], 422);
        }

        DB::connection('tenant')->transaction(function () use ($expense, $request) {
            $expense->update(['status' => 'posted']);

            $this->accounting->post(
                entries: [
                    ['account' => 'EXPENSE', 'debit' => $expense->amount, 'credit' => 0],
                    ['account' => 'GST_INPUT', 'debit' => $expense->gst_amount, 'credit' => 0],
                    ['account' => 'CASH_BANK', 'debit' => 0, 'credit' => $expense->total_amount],
                ],
                voucherNumber: $expense->expense_number,
                date: $expense->expense_date,
                entryable: $expense,
                createdBy: $request->user()->id,
            );
        });

        return response()->json(['data' => $expense->fresh(), 'meta' => [], 'message' => 'Expense posted.']);
    }

    public function cancel(Request $request, Expense $expense): JsonResponse
    {
        if ($expense->status === 'cancelled') {
            return response()->json(['message' => 'Already cancelled.'], 422);
        }

        DB::connection('tenant')->transaction(function () use ($expense, $request) {
            if ($expense->status === 'posted') {
                $this->accounting->reverse(
                    entryable: $expense,
                    date: now()->toDateString(),
                    voucherNumber: 'REV-' . $expense->expense_number,
                    createdBy: $request->user()->id,
                );
            }
            $expense->update(['status' => 'cancelled']);
        });

        return response()->json(['data' => $expense->fresh(), 'meta' => [], 'message' => 'Expense cancelled.']);
    }
}
