<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes — Hexbase Retail
|--------------------------------------------------------------------------
|
| All routes are versioned under /api/v1.
| The TenantResolver middleware runs on every v1 route.
| Sanctum auth protects all authenticated routes.
|
*/

Route::get('/health', fn () => response()->json(['status' => 'ok', 'timestamp' => now()->toISOString()]));

Route::prefix('v1')->group(function () {

    // ── Auth (public) ────────────────────────────────────────────────────
    Route::prefix('auth')->group(function () {
        Route::post('login', [\App\Http\Controllers\Api\V1\AuthController::class, 'login'])
            ->middleware('throttle:10,1');
        Route::post('logout', [\App\Http\Controllers\Api\V1\AuthController::class, 'logout'])
            ->middleware('auth:sanctum');
        Route::get('profile', [\App\Http\Controllers\Api\V1\AuthController::class, 'profile'])
            ->middleware('auth:sanctum');
    });

    // ── Authenticated routes ─────────────────────────────────────────────
    Route::middleware(['auth:sanctum'])->group(function () {

        // Masters
        Route::apiResource('customers', \App\Http\Controllers\Api\V1\CustomerController::class);
        Route::get('customers/search', [\App\Http\Controllers\Api\V1\CustomerController::class, 'search']);

        Route::apiResource('vendors', \App\Http\Controllers\Api\V1\VendorController::class);
        Route::get('vendors/search', [\App\Http\Controllers\Api\V1\VendorController::class, 'search']);

        Route::apiResource('products', \App\Http\Controllers\Api\V1\ProductController::class);
        Route::get('products/search', [\App\Http\Controllers\Api\V1\ProductController::class, 'search']);
        Route::get('products/stock-summary', [\App\Http\Controllers\Api\V1\ProductController::class, 'stockSummary']);
        Route::get('products/{product}/movements', [\App\Http\Controllers\Api\V1\ProductController::class, 'movements']);
        Route::post('products/{product}/stock-adjustment', [\App\Http\Controllers\Api\V1\ProductController::class, 'stockAdjustment']);

        // Sales
        Route::prefix('invoices')->group(function () {
            Route::post('calculate', [\App\Http\Controllers\Api\V1\SalesInvoiceController::class, 'calculate']);
        });
        Route::apiResource('invoices', \App\Http\Controllers\Api\V1\SalesInvoiceController::class);
        Route::post('invoices/{invoice}/post', [\App\Http\Controllers\Api\V1\SalesInvoiceController::class, 'post']);
        Route::post('invoices/{invoice}/cancel', [\App\Http\Controllers\Api\V1\SalesInvoiceController::class, 'cancel']);
        Route::get('invoices/{invoice}/pdf', [\App\Http\Controllers\Api\V1\SalesInvoiceController::class, 'pdf']);

        // Purchases
        Route::apiResource('purchase-invoices', \App\Http\Controllers\Api\V1\PurchaseInvoiceController::class);
        Route::post('purchase-invoices/{purchaseInvoice}/post', [\App\Http\Controllers\Api\V1\PurchaseInvoiceController::class, 'post']);
        Route::post('purchase-invoices/{purchaseInvoice}/cancel', [\App\Http\Controllers\Api\V1\PurchaseInvoiceController::class, 'cancel']);
        Route::post('purchase-invoices/{purchaseInvoice}/attach', [\App\Http\Controllers\Api\V1\PurchaseInvoiceController::class, 'attach']);

        // Receipts
        Route::apiResource('receipts', \App\Http\Controllers\Api\V1\ReceiptController::class);
        Route::post('receipts/{receipt}/post', [\App\Http\Controllers\Api\V1\ReceiptController::class, 'post']);
        Route::post('receipts/{receipt}/cancel', [\App\Http\Controllers\Api\V1\ReceiptController::class, 'cancel']);

        // Payments
        Route::apiResource('payments', \App\Http\Controllers\Api\V1\PaymentController::class);
        Route::post('payments/{payment}/post', [\App\Http\Controllers\Api\V1\PaymentController::class, 'post']);
        Route::post('payments/{payment}/cancel', [\App\Http\Controllers\Api\V1\PaymentController::class, 'cancel']);

        // Quotations
        Route::apiResource('quotations', \App\Http\Controllers\Api\V1\QuotationController::class);
        Route::post('quotations/{quotation}/post', [\App\Http\Controllers\Api\V1\QuotationController::class, 'post']);
        Route::post('quotations/{quotation}/convert', [\App\Http\Controllers\Api\V1\QuotationController::class, 'convert']);

        // Reports — GST
        Route::prefix('reports/gst')->group(function () {
            Route::get('gstr1', [\App\Http\Controllers\Api\V1\Reports\GstReportController::class, 'gstr1']);
            Route::get('gstr3b-support', [\App\Http\Controllers\Api\V1\Reports\GstReportController::class, 'gstr3bSupport']);
            Route::get('hsn-summary', [\App\Http\Controllers\Api\V1\Reports\GstReportController::class, 'hsnSummary']);
            Route::get('itc-register', [\App\Http\Controllers\Api\V1\Reports\GstReportController::class, 'itcRegister']);
            Route::get('sales-tax-register', [\App\Http\Controllers\Api\V1\Reports\GstReportController::class, 'salesTaxRegister']);
            Route::get('purchase-tax-register', [\App\Http\Controllers\Api\V1\Reports\GstReportController::class, 'purchaseTaxRegister']);
        });

        // Reports — Financial
        Route::prefix('reports/financial')->group(function () {
            Route::get('trial-balance', [\App\Http\Controllers\Api\V1\Reports\FinancialReportController::class, 'trialBalance']);
            Route::get('profit-loss', [\App\Http\Controllers\Api\V1\Reports\FinancialReportController::class, 'profitLoss']);
            Route::get('balance-sheet', [\App\Http\Controllers\Api\V1\Reports\FinancialReportController::class, 'balanceSheet']);
            Route::get('day-book', [\App\Http\Controllers\Api\V1\Reports\FinancialReportController::class, 'dayBook']);
            Route::get('cash-book', [\App\Http\Controllers\Api\V1\Reports\FinancialReportController::class, 'cashBook']);
            Route::get('sales-register', [\App\Http\Controllers\Api\V1\Reports\FinancialReportController::class, 'salesRegister']);
            Route::get('purchase-register', [\App\Http\Controllers\Api\V1\Reports\FinancialReportController::class, 'purchaseRegister']);
            Route::get('cash-flow', [\App\Http\Controllers\Api\V1\Reports\FinancialReportController::class, 'cashFlow']);
            Route::get('ledger/{account_id}', [\App\Http\Controllers\Api\V1\Reports\FinancialReportController::class, 'ledger']);
            Route::get('receivables-ageing', [\App\Http\Controllers\Api\V1\Reports\FinancialReportController::class, 'receivablesAgeing']);
            Route::get('payables-ageing', [\App\Http\Controllers\Api\V1\Reports\FinancialReportController::class, 'payablesAgeing']);
        });

        // Credit Notes
        Route::apiResource('credit-notes', \App\Http\Controllers\Api\V1\CreditNoteController::class);
        Route::post('credit-notes/{creditNote}/post', [\App\Http\Controllers\Api\V1\CreditNoteController::class, 'post']);
        Route::post('credit-notes/{creditNote}/cancel', [\App\Http\Controllers\Api\V1\CreditNoteController::class, 'cancel']);
        Route::get('credit-notes/{creditNote}/pdf', [\App\Http\Controllers\Api\V1\CreditNoteController::class, 'pdf']);

        // Debit Notes
        Route::apiResource('debit-notes', \App\Http\Controllers\Api\V1\DebitNoteController::class);
        Route::post('debit-notes/{debitNote}/post', [\App\Http\Controllers\Api\V1\DebitNoteController::class, 'post']);
        Route::post('debit-notes/{debitNote}/cancel', [\App\Http\Controllers\Api\V1\DebitNoteController::class, 'cancel']);
        Route::get('debit-notes/{debitNote}/pdf', [\App\Http\Controllers\Api\V1\DebitNoteController::class, 'pdf']);

        // Purchase Orders
        Route::apiResource('purchase-orders', \App\Http\Controllers\Api\V1\PurchaseOrderController::class);
        Route::post('purchase-orders/{purchaseOrder}/cancel', [\App\Http\Controllers\Api\V1\PurchaseOrderController::class, 'cancel']);

        // Delivery Challans
        Route::apiResource('delivery-challans', \App\Http\Controllers\Api\V1\DeliveryChallanController::class);
        Route::post('delivery-challans/{deliveryChallan}/dispatch', [\App\Http\Controllers\Api\V1\DeliveryChallanController::class, 'dispatch']);
        Route::post('delivery-challans/{deliveryChallan}/cancel', [\App\Http\Controllers\Api\V1\DeliveryChallanController::class, 'cancel']);
        Route::get('delivery-challans/{deliveryChallan}/pdf', [\App\Http\Controllers\Api\V1\DeliveryChallanController::class, 'pdf']);

        // Expenses
        Route::apiResource('expenses', \App\Http\Controllers\Api\V1\ExpenseController::class);
        Route::post('expenses/{expense}/post', [\App\Http\Controllers\Api\V1\ExpenseController::class, 'post']);
        Route::post('expenses/{expense}/cancel', [\App\Http\Controllers\Api\V1\ExpenseController::class, 'cancel']);

        // Admin
        Route::prefix('admin')->group(function () {
            Route::middleware('role:admin')->group(function () {
                Route::get('company', [\App\Http\Controllers\Api\V1\Admin\CompanySettingsController::class, 'show']);
                Route::put('company', [\App\Http\Controllers\Api\V1\Admin\CompanySettingsController::class, 'update']);
                Route::post('company/logo', [\App\Http\Controllers\Api\V1\Admin\CompanySettingsController::class, 'uploadLogo']);

                Route::apiResource('bank-accounts', \App\Http\Controllers\Api\V1\Admin\BankAccountController::class);
                Route::patch('bank-accounts/{bankAccount}/toggle-active', [\App\Http\Controllers\Api\V1\Admin\BankAccountController::class, 'toggleActive']);

                Route::get('numbering-sequences', [\App\Http\Controllers\Api\V1\Admin\NumberingSequenceController::class, 'index']);
                Route::put('numbering-sequences/{id}', [\App\Http\Controllers\Api\V1\Admin\NumberingSequenceController::class, 'update']);

                Route::apiResource('users', \App\Http\Controllers\Api\V1\Admin\UsersController::class);
                Route::patch('users/{user}/deactivate', [\App\Http\Controllers\Api\V1\Admin\UsersController::class, 'deactivate']);

                Route::get('activity-log', [\App\Http\Controllers\Api\V1\Admin\ActivityLogController::class, 'index']);

                Route::apiResource('custom-fields', \App\Http\Controllers\Api\V1\Admin\CustomFieldController::class);

                Route::apiResource('pdf-templates', \App\Http\Controllers\Api\V1\Admin\PdfTemplateController::class);
                Route::post('pdf-templates/{id}/set-default', [\App\Http\Controllers\Api\V1\Admin\PdfTemplateController::class, 'setDefault']);

                Route::get('backups', [\App\Http\Controllers\Api\V1\Admin\BackupController::class, 'index']);
                Route::post('backups', [\App\Http\Controllers\Api\V1\Admin\BackupController::class, 'store']);
                Route::get('backups/{id}/download', [\App\Http\Controllers\Api\V1\Admin\BackupController::class, 'download']);
            });

            Route::middleware('role:super-admin')->group(function () {
                Route::post('tenants', [\App\Http\Controllers\Api\V1\Admin\TenantController::class, 'store']);
            });
        });
    });
});
