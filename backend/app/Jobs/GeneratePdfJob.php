<?php

namespace App\Jobs;

use App\Services\PdfService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;

class GeneratePdfJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $timeout = 60;

    /**
     * @param  string $documentType  e.g. 'sales_invoice', 'quotation'
     * @param  int    $documentId
     * @param  string $tenantCode    Required to re-switch DB connection in queue worker
     * @param  string $tenantDbName  Full DB name e.g. 'hexbase_acme'
     */
    public function __construct(
        public readonly string $documentType,
        public readonly int $documentId,
        public readonly string $tenantCode,
        public readonly string $tenantDbName,
    ) {}

    public function handle(PdfService $pdfService): void
    {
        // Re-connect to tenant DB inside the queue worker
        config(['database.connections.tenant.database' => $this->tenantDbName]);
        DB::purge('tenant');

        [$view, $table, $filename] = match ($this->documentType) {
            'sales_invoice'    => ['pdf.sales_invoice',    'sales_invoices',    "INV-{$this->documentId}.pdf"],
            'quotation'        => ['pdf.quotation',        'quotations',        "QT-{$this->documentId}.pdf"],
            'purchase_invoice' => ['pdf.purchase_invoice', 'purchase_invoices', "PINV-{$this->documentId}.pdf"],
            'credit_note'      => ['pdf.credit_note',      'credit_notes',      "CN-{$this->documentId}.pdf"],
            'debit_note'       => ['pdf.debit_note',       'debit_notes',       "DN-{$this->documentId}.pdf"],
            default            => throw new \InvalidArgumentException("Unknown document type: {$this->documentType}"),
        };

        $document = DB::connection('tenant')->table($table)->find($this->documentId);
        if (! $document) {
            return; // Document was deleted
        }

        $storagePath = "tenants/{$this->tenantCode}/pdfs/{$this->documentType}/{$filename}";
        $pdfService->save($view, ['document' => $document], $storagePath);

        DB::connection('tenant')->table($table)
            ->where('id', $this->documentId)
            ->update(['pdf_path' => $storagePath, 'updated_at' => now()]);
    }
}
