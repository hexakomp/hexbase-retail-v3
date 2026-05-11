<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\BankAccount;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BankAccountController extends Controller
{
    public function index(): JsonResponse
    {
        $accounts = BankAccount::orderBy('bank_name')->get();

        return response()->json(['data' => $accounts, 'meta' => [], 'message' => 'OK']);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'           => ['required', 'string', 'max:200'],
            'bank_name'      => ['nullable', 'string', 'max:200'],
            'account_number' => ['nullable', 'string', 'max:50'],
            'ifsc'           => ['nullable', 'string', 'max:20'],
            'branch'         => ['nullable', 'string', 'max:200'],
            'is_default'     => ['boolean'],
        ]);

        $account = BankAccount::create(array_merge($data, ['is_active' => true]));

        return response()->json(['data' => $account, 'meta' => [], 'message' => 'Bank account created.'], 201);
    }

    public function show(BankAccount $bankAccount): JsonResponse
    {
        return response()->json(['data' => $bankAccount, 'meta' => [], 'message' => 'OK']);
    }

    public function update(Request $request, BankAccount $bankAccount): JsonResponse
    {
        $data = $request->validate([
            'name'           => ['required', 'string', 'max:200'],
            'bank_name'      => ['nullable', 'string', 'max:200'],
            'account_number' => ['nullable', 'string', 'max:50'],
            'ifsc'           => ['nullable', 'string', 'max:20'],
            'branch'         => ['nullable', 'string', 'max:200'],
            'is_default'     => ['boolean'],
        ]);

        $bankAccount->update($data);

        return response()->json(['data' => $bankAccount->fresh(), 'meta' => [], 'message' => 'Bank account updated.']);
    }

    public function destroy(BankAccount $bankAccount): JsonResponse
    {
        $bankAccount->delete();

        return response()->json(['data' => null, 'meta' => [], 'message' => 'Bank account deleted.']);
    }

    public function toggleActive(BankAccount $bankAccount): JsonResponse
    {
        $bankAccount->update(['is_active' => !$bankAccount->is_active]);

        return response()->json(['data' => $bankAccount->fresh(), 'meta' => [], 'message' => 'Status toggled.']);
    }
}
