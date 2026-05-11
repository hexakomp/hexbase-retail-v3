<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;
use App\Models\User;

class AuthController extends Controller
{
    /**
     * Login — returns Sanctum token.
     * Rate limiting (10/min) is applied at the route level.
     */
    public function login(Request $request): JsonResponse
    {
        $credentials = $request->validate([
            'email'    => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        if (! Auth::attempt($credentials)) {
            return response()->json([
                'data'    => null,
                'meta'    => [],
                'message' => 'Invalid credentials.',
            ], 401);
        }

        /** @var User $user */
        $user = Auth::user();

        if (! $user->is_active) {
            Auth::logout();

            return response()->json([
                'data'    => null,
                'meta'    => [],
                'message' => 'Your account has been deactivated.',
            ], 403);
        }

        $token = $user->createToken('api-token')->plainTextToken;
        $roles = $user->getRoleNames();

        return response()->json([
            'data' => [
                'token' => $token,
                'user'  => [
                    'id'    => $user->id,
                    'name'  => $user->name,
                    'email' => $user->email,
                ],
                'roles' => $roles,
            ],
            'meta'    => [],
            'message' => 'Login successful.',
        ]);
    }

    /**
     * Logout — revoke current token.
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'data'    => null,
            'meta'    => [],
            'message' => 'Logged out successfully.',
        ]);
    }

    /**
     * Return authenticated user profile.
     */
    public function profile(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'data' => [
                'id'          => $user->id,
                'name'        => $user->name,
                'email'       => $user->email,
                'roles'       => $user->getRoleNames(),
                'permissions' => $user->getAllPermissions()->pluck('name'),
            ],
            'meta'    => [],
            'message' => 'OK',
        ]);
    }

    /**
     * Change password for authenticated user.
     */
    public function changePassword(Request $request): JsonResponse
    {
        $request->validate([
            'current_password' => ['required', 'string'],
            'password'         => ['required', 'confirmed', Password::min(8)],
        ]);

        $user = $request->user();

        if (! Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'data'    => null,
                'meta'    => [],
                'message' => 'Current password is incorrect.',
            ], 422);
        }

        $user->update(['password' => Hash::make($request->password)]);

        return response()->json([
            'data'    => null,
            'meta'    => [],
            'message' => 'Password changed successfully.',
        ]);
    }
}
