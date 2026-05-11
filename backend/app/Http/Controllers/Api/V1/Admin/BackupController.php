<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Jobs\BackupJob;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class BackupController extends Controller
{
    public function index(): JsonResponse
    {
        $files = collect(Storage::disk('local')->files('backups'))
            ->map(fn($path) => [
                'id'       => basename($path),
                'name'     => basename($path),
                'size'     => Storage::disk('local')->size($path),
                'created'  => Storage::disk('local')->lastModified($path),
            ])
            ->sortByDesc('created')
            ->values()
            ->all();

        return response()->json(['data' => $files, 'meta' => ['total' => count($files)], 'message' => 'OK']);
    }

    public function store(Request $request): JsonResponse
    {
        BackupJob::dispatch($request->user()->id);

        return response()->json(['data' => null, 'meta' => [], 'message' => 'Backup job queued.'], 202);
    }

    public function download(Request $request, string $id): StreamedResponse|JsonResponse
    {
        $path = 'backups/' . $id;

        if (!Storage::disk('local')->exists($path)) {
            return response()->json(['message' => 'File not found.'], 404);
        }

        return Storage::disk('local')->download($path);
    }
}
