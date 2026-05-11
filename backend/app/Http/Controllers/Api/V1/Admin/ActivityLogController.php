<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ActivityLogController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = DB::connection('tenant')->table('activity_log')
            ->when($request->input('user_id'), fn($q, $uid) => $q->where('causer_id', $uid))
            ->when($request->input('model'), fn($q, $m) => $q->where('subject_type', 'like', "%{$m}"))
            ->orderByDesc('created_at');

        $log = $query->paginate(50);

        return response()->json([
            'data'    => $log->items(),
            'meta'    => [
                'current_page' => $log->currentPage(),
                'last_page'    => $log->lastPage(),
                'total'        => $log->total(),
            ],
            'message' => 'OK',
        ]);
    }
}
