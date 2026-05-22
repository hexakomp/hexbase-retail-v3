<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class CompanySettingsController extends Controller
{
    private const SETTINGS_KEY = 'company_settings';

    public function show(): JsonResponse
    {
        $settings = cache()->remember(
            self::SETTINGS_KEY,
            now()->addHour(),
            function () {
                $dbSettings = DB::connection('tenant')->table('company_settings')->first();
                if ($dbSettings) {
                    $arr = (array) $dbSettings;
                    $arr['name'] = $arr['company_name'] ?? ''; // Map company_name DB column to expected API 'name'
                    return $arr;
                }
                return [];
            }
        );

        return response()->json(['data' => $settings ?: new \stdClass(), 'meta' => [], 'message' => 'OK']);
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
            'cin'              => ['nullable', 'string', 'max:50'],
            'bank_name'        => ['nullable', 'string'],
            'bank_account_no'  => ['nullable', 'string'],
            'bank_ifsc'        => ['nullable', 'string'],
            'bank_branch'      => ['nullable', 'string'],
            'invoice_terms'    => ['nullable', 'string'],
            'invoice_footer'   => ['nullable', 'string'],
        ]);

        $updateData = [
            'company_name'     => $data['name'],
            'legal_name'       => $data['legal_name'] ?? null,
            'gstin'            => $data['gstin'] ?? null,
            'pan'              => $data['pan'] ?? null,
            'cin'              => $data['cin'] ?? null,
            'address'          => $data['address'] ?? null,
            'city'             => $data['city'] ?? null,
            'state'            => $data['state'] ?? null,
            'state_code'       => $data['state_code'] ?? null,
            'pincode'          => $data['pincode'] ?? null,
            'email'            => $data['email'] ?? null,
            'phone'            => $data['phone'] ?? null,
            'website'          => $data['website'] ?? null,
            'bank_name'        => $data['bank_name'] ?? null,
            'bank_account_no'  => $data['bank_account_no'] ?? null,
            'bank_ifsc'        => $data['bank_ifsc'] ?? null,
            'bank_branch'      => $data['bank_branch'] ?? null,
            'invoice_terms'    => $data['invoice_terms'] ?? null,
            'invoice_footer'   => $data['invoice_footer'] ?? null,
            'updated_at'       => now(),
        ];

        $exists = DB::connection('tenant')->table('company_settings')->first();
        if ($exists) {
            DB::connection('tenant')->table('company_settings')->update($updateData);
        } else {
            $updateData['created_at'] = now();
            DB::connection('tenant')->table('company_settings')->insert($updateData);
        }

        cache()->forget(self::SETTINGS_KEY);

        return response()->json(['data' => $data, 'meta' => [], 'message' => 'Settings updated.']);
    }

    public function uploadLogo(Request $request): JsonResponse
    {
        $request->validate([
            'logo' => ['required', 'image', 'max:2048', 'mimes:jpg,jpeg,png,svg'],
        ]);

        $path = $request->file('logo')->store('company', 'local');
        
        $exists = DB::connection('tenant')->table('company_settings')->first();
        if ($exists) {
            DB::connection('tenant')->table('company_settings')->update(['logo_path' => $path]);
        }
        cache()->forget(self::SETTINGS_KEY);

        return response()->json(['data' => ['logo_path' => $path], 'meta' => [], 'message' => 'Logo uploaded.']);
    }
}
