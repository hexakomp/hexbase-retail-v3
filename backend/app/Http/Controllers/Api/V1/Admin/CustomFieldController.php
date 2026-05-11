<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\CustomField;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CustomFieldController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $fields = CustomField::when(
            $request->input('entity_type'),
            fn($q, $t) => $q->where('entity_type', $t)
        )->orderBy('entity_type')->orderBy('field_name')->get();

        return response()->json(['data' => $fields, 'meta' => [], 'message' => 'OK']);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'entity_type' => ['required', 'string', 'in:customer,vendor,product,invoice,expense'],
            'field_name'  => ['required', 'string', 'max:100'],
            'field_label' => ['required', 'string', 'max:200'],
            'field_type'  => ['required', 'in:text,number,date,select,checkbox'],
            'options'     => ['nullable', 'array'],
            'is_required' => ['nullable', 'boolean'],
            'sort_order'  => ['nullable', 'integer'],
        ]);

        $field = CustomField::create($data);

        return response()->json(['data' => $field, 'meta' => [], 'message' => 'Custom field created.'], 201);
    }

    public function show(CustomField $customField): JsonResponse
    {
        return response()->json(['data' => $customField, 'meta' => [], 'message' => 'OK']);
    }

    public function update(Request $request, CustomField $customField): JsonResponse
    {
        $data = $request->validate([
            'field_label' => ['required', 'string', 'max:200'],
            'field_type'  => ['required', 'in:text,number,date,select,checkbox'],
            'options'     => ['nullable', 'array'],
            'is_required' => ['nullable', 'boolean'],
            'sort_order'  => ['nullable', 'integer'],
        ]);

        $customField->update($data);

        return response()->json(['data' => $customField->fresh(), 'meta' => [], 'message' => 'Custom field updated.']);
    }

    public function destroy(CustomField $customField): JsonResponse
    {
        $customField->delete();

        return response()->json(['data' => null, 'meta' => [], 'message' => 'Custom field deleted.']);
    }
}
