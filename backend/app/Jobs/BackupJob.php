<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\Process\Exception\ProcessFailedException;
use Symfony\Component\Process\Process;

class BackupJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public readonly int $initiatedBy,
    ) {}

    public function handle(): void
    {
        $db       = config('database.connections.tenant.database');
        $user     = config('database.connections.tenant.username');
        $password = config('database.connections.tenant.password');
        $host     = config('database.connections.tenant.host');
        $timestamp = now()->format('Y-m-d_H-i-s');
        $sqlFile  = storage_path("app/backups/{$db}_{$timestamp}.sql");
        $zipFile  = $sqlFile . '.zip';

        // Ensure backup dir exists
        Storage::disk('local')->makeDirectory('backups');

        // Dump SQL
        $dump = Process::fromShellCommandline(
            "mysqldump --single-transaction --no-tablespaces -h {$host} -u {$user} " .
            ($password ? "-p\"{$password}\" " : "") .
            $db . " > \"{$sqlFile}\""
        );
        $dump->setTimeout(300)->run();

        if (!$dump->isSuccessful()) {
            Log::error('BackupJob: mysqldump failed', ['error' => $dump->getErrorOutput()]);
            throw new ProcessFailedException($dump);
        }

        // Zip the SQL file
        $zip = new \ZipArchive();
        if ($zip->open($zipFile, \ZipArchive::CREATE) !== true) {
            throw new \RuntimeException("Cannot create ZIP archive: {$zipFile}");
        }
        $zip->addFile($sqlFile, basename($sqlFile));
        $zip->close();

        // Remove raw SQL
        @unlink($sqlFile);

        Log::info("BackupJob: backup created", [
            'file'         => $zipFile,
            'initiated_by' => $this->initiatedBy,
        ]);
    }
}
