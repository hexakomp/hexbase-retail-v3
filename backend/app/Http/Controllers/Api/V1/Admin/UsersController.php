<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UsersController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = User::with('roles')->when(
            $request->input('search'),
            fn($q, $s) => $q->where('name', 'like', "%{$s}%")->orWhere('email', 'like', "%{$s}%")
        );

        $users = $query->latest()->paginate(20);

        return response()->json([
            'data'    => $users->items(),
            'meta'    => [
                'current_page' => $users->currentPage(),
                'last_page'    => $users->lastPage(),
                'total'        => $users->total(),
            ],
            'message' => 'OK',
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'     => ['required', 'string', 'max:200'],
            'email'    => ['required', 'email', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
            'role'     => ['required', 'string'],
        ]);

        $user = User::create([
            'name'     => $data['name'],
            'email'    => $data['email'],
            'password' => Hash::make($data['password']),
        ]);

        $user->assignRole($data['role']);

        return response()->json(['data' => $user->load('roles'), 'meta' => [], 'message' => 'User created.'], 201);
    }

    public function show(User $user): JsonResponse
    {
        return response()->json(['data' => $user->load('roles'), 'meta' => [], 'message' => 'OK']);
    }

    public function update(Request $request, User $user): JsonResponse
    {
        $data = $request->validate([
            'name'     => ['required', 'string', 'max:200'],
            'email'    => ['required', 'email', "unique:users,email,{$user->id}"],
            'role'     => ['required', 'string'],
            'password' => ['nullable', 'string', 'min:8'],
        ]);

        $user->update([
            'name'  => $data['name'],
            'email' => $data['email'],
            ...(isset($data['password']) ? ['password' => Hash::make($data['password'])] : []),
        ]);

        $user->syncRoles([$data['role']]);

        return response()->json(['data' => $user->fresh()->load('roles'), 'meta' => [], 'message' => 'User updated.']);
    }

    public function destroy(User $user): JsonResponse
    {
        $user->delete();

        return response()->json(['data' => null, 'meta' => [], 'message' => 'User deleted.']);
    }

    public function deactivate(User $user): JsonResponse
    {
        $user->update(['is_active' => false]);

        return response()->json(['data' => $user->fresh(), 'meta' => [], 'message' => 'User deactivated.']);
    }
}
