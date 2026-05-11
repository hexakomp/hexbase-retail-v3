<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class CompanySettingsController extends Controller
{
    private const SETTINGS_KEY = 'company_settings';

    public function show(): JsonResponse
    {
        $settings = cache()->remember(
            self::SETTINGS_KEY,
            now()->addHour(),
            fn() => config('tenancy.company_settings', [])
        );

        return response()->json(['data' => $settings, 'meta' => [], 'message' => 'OK']);
    }

    public function update(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'             => ['required', 'string', 'max:200'],
            'legal_name'       => ['nullable', 'string', 'max:200'],
            'gstin'            => ['nullable', 'string', 'max:15'],
            'pan'              => ['nullable', 'string', 'max:10'],
            'address'          => ['nullable', 'string'],
            'city'             => ['nullable', 'string', 'max:100'],
            'state'            => ['nullable', 'string', 'max:100'],
            'state_code'       => ['nullable', 'string', 'max:5'],
            'pincode'          => ['nullable', 'string', 'max:10'],
            'email'            => ['nullable', 'email'],
            'phone'            => ['nullable', 'string', 'max:20'],
            'website'          => ['nullable', 'url'],
            'bank_name'        => ['nullable', 'string'],
            'bank_account_no'  => ['nullable', 'string'],
            'bank_ifsc'        => ['nullable', 'string'],
            'invoice_terms'    => ['nullable', 'string'],
            'invoice_footer'   => ['nullable', 'string'],
        ]);

        // Persist to a JSON file in storage
        Storage::disk('local')->put(
            'company/settings.json',
            json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)
        );

        cache()->forget(self::SETTINGS_KEY);

        return response()->json(['data' => $data, 'meta' => [], 'message' => 'Settings updated.']);
    }

    public function uploadLogo(Request $request): JsonResponse
    {
        $request->validate([
            'logo' => ['required', 'image', 'max:2048', 'mimes:jpg,jpeg,png,svg'],
        ]);

        $path = $request->file('logo')->store('company', 'local');

        return response()->json(['data' => ['logo_path' => $path], 'meta' => [], 'message' => 'Logo uploaded.']);
    }
}
