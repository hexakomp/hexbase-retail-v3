<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\PdfTemplate;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PdfTemplateController extends Controller
{
    private const VALID_TYPES = [
        'sales_invoice', 'credit_note', 'debit_note',
        'purchase_order', 'delivery_challan', 'quotation',
    ];

    public function index(Request $request): JsonResponse
    {
        $templates = PdfTemplate::when(
            $request->input('document_type'),
            fn($q, $t) => $q->forType($t)
        )->orderBy('document_type')->orderByDesc('is_default')->get();

        return response()->json(['data' => $templates, 'meta' => [], 'message' => 'OK']);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'          => ['required', 'string', 'max:200'],
            'document_type' => ['required', 'in:' . implode(',', self::VALID_TYPES)],
            'template_html' => ['required', 'string'],
            'is_default'    => ['nullable', 'boolean'],
        ]);

        $template = PdfTemplate::create([
            ...$data,
            'is_default' => $data['is_default'] ?? false,
            'created_by' => $request->user()->id,
        ]);

        return response()->json(['data' => $template, 'meta' => [], 'message' => 'Template created.'], 201);
    }

    public function show(PdfTemplate $pdfTemplate): JsonResponse
    {
        return response()->json(['data' => $pdfTemplate, 'meta' => [], 'message' => 'OK']);
    }

    public function update(Request $request, PdfTemplate $pdfTemplate): JsonResponse
    {
        $data = $request->validate([
            'name'          => ['required', 'string', 'max:200'],
            'template_html' => ['required', 'string'],
        ]);

        $pdfTemplate->update($data);

        return response()->json(['data' => $pdfTemplate->fresh(), 'meta' => [], 'message' => 'Template updated.']);
    }

    public function destroy(PdfTemplate $pdfTemplate): JsonResponse
    {
        $pdfTemplate->delete();

        return response()->json(['data' => null, 'meta' => [], 'message' => 'Template deleted.']);
    }

    public function setDefault(Request $request, int $id): JsonResponse
    {
        $template = PdfTemplate::findOrFail($id);

        DB::connection('tenant')->transaction(function () use ($template) {
            PdfTemplate::forType($template->document_type)->update(['is_default' => false]);
            $template->update(['is_default' => true]);
        });

        return response()->json(['data' => $template->fresh(), 'meta' => [], 'message' => 'Default set.']);
    }
}
