<?php

namespace App\Exceptions;

use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Throwable;

class Handler extends ExceptionHandler
{
    protected $dontFlash = [
        'current_password',
        'password',
        'password_confirmation',
    ];

    public function register(): void
    {
        $this->renderable(function (Throwable $e, Request $request): JsonResponse|null {
            if ($request->expectsJson() || $request->is('api/*')) {
                return $this->apiResponse($e, $request);
            }
            return null;
        });
    }

    private function apiResponse(Throwable $e, Request $request): JsonResponse
    {
        if ($e instanceof ValidationException) {
            return response()->json([
                'data'    => null,
                'meta'    => ['errors' => $e->errors()],
                'message' => 'Validation failed.',
            ], 422);
        }

        if ($e instanceof AccountingImbalanceException) {
            return response()->json([
                'data'    => null,
                'meta'    => [],
                'message' => $e->getMessage(),
            ], 422);
        }

        if ($e instanceof AuthenticationException) {
            return response()->json([
                'data'    => null,
                'meta'    => [],
                'message' => 'Unauthenticated.',
            ], 401);
        }

        if ($e instanceof HttpException) {
            return response()->json([
                'data'    => null,
                'meta'    => [],
                'message' => $e->getMessage() ?: 'HTTP error.',
            ], $e->getStatusCode());
        }

        $status  = method_exists($e, 'getStatusCode') ? $e->getStatusCode() : 500;
        $message = app()->isProduction() ? 'Server error.' : $e->getMessage();

        return response()->json([
            'data'    => null,
            'meta'    => [],
            'message' => $message,
        ], $status);
    }
}
