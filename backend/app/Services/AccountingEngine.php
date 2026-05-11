<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

/**
 * AccountingEngine — Posts double-entry ledger entries.
 */
class AccountingEngine
{
    /**
     * Post a set of debit/credit entries as a single journal entry.
     *
     * @param  array<array{account_code: string, debit: float, credit: float, narration?: string}> $entries
     * @param  string  $voucherNumber
     * @param  string  $date          YYYY-MM-DD
     * @param  object  $entryable     Eloquent model instance (polymorphic)
     * @param  int|null $createdBy
     */
    public function post(array $entries, string $voucherNumber, string $date, object $entryable, ?int $createdBy = null): void
    {
        $this->assertBalanced($entries);

        $accounts = DB::connection('tenant')
            ->table('chart_of_accounts')
            ->whereIn('code', array_column($entries, 'account_code'))
            ->pluck('id', 'code');

        $rows = [];
        $now  = now();

        foreach ($entries as $entry) {
            $accountId = $accounts[$entry['account_code']] ?? null;
            if (! $accountId) {
                throw new \RuntimeException("Chart of account not found for code: {$entry['account_code']}");
            }

            $rows[] = [
                'entry_date'      => $date,
                'account_id'      => $accountId,
                'entryable_type'  => get_class($entryable),
                'entryable_id'    => $entryable->id,
                'debit_amount'    => $entry['debit'] ?? 0,
                'credit_amount'   => $entry['credit'] ?? 0,
                'narration'       => $entry['narration'] ?? null,
                'voucher_number'  => $voucherNumber,
                'created_by'      => $createdBy,
                'created_at'      => $now,
                'updated_at'      => $now,
            ];
        }

        DB::connection('tenant')->table('ledger_entries')->insert($rows);
    }

    /**
     * Reverse all ledger entries for an entryable (e.g. on cancellation).
     */
    public function reverse(object $entryable, string $date, string $voucherNumber, ?int $createdBy = null): void
    {
        $original = DB::connection('tenant')
            ->table('ledger_entries')
            ->where('entryable_type', get_class($entryable))
            ->where('entryable_id', $entryable->id)
            ->get();

        $rows = [];
        $now  = now();

        foreach ($original as $entry) {
            $rows[] = [
                'entry_date'     => $date,
                'account_id'     => $entry->account_id,
                'entryable_type' => $entry->entryable_type,
                'entryable_id'   => $entry->entryable_id,
                'debit_amount'   => $entry->credit_amount,  // swap
                'credit_amount'  => $entry->debit_amount,   // swap
                'narration'      => 'Reversal: ' . ($entry->narration ?? ''),
                'voucher_number' => $voucherNumber,
                'created_by'     => $createdBy,
                'created_at'     => $now,
                'updated_at'     => $now,
            ];
        }

        if (! empty($rows)) {
            DB::connection('tenant')->table('ledger_entries')->insert($rows);
        }
    }

    /**
     * Validate that total debits equal total credits.
     */
    private function assertBalanced(array $entries): void
    {
        $totalDebit  = array_sum(array_column($entries, 'debit'));
        $totalCredit = array_sum(array_column($entries, 'credit'));

        if (abs($totalDebit - $totalCredit) > 0.001) {
            throw new \RuntimeException(
                "Journal entry is unbalanced. Debit: {$totalDebit}, Credit: {$totalCredit}"
            );
        }
    }
}
