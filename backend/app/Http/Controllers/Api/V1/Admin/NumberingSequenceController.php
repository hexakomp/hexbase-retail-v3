<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\NumberingSequence;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NumberingSequenceController extends Controller
{
    public function index(): JsonResponse
    {
        $sequences = NumberingSequence::orderBy('type')->get();

        return response()->json(['data' => $sequences, 'meta' => [], 'message' => 'OK']);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $sequence = NumberingSequence::findOrFail($id);

        $data = $request->validate([
            'prefix'      => ['nullable', 'string', 'max:20'],
            'next_number' => ['required', 'integer', 'min:1'],
            'padding'     => ['nullable', 'integer', 'min:1', 'max:10'],
        ]);

        $sequence->update($data);

        return response()->json(['data' => $sequence->fresh(), 'meta' => [], 'message' => 'Sequence updated.']);
    }
}
