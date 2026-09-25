<?php

namespace App\Http\Controllers\Api\V1;

use App\Application\Auth\LoginUser;
use App\Application\Auth\RegisterUser;
use App\Http\Controllers\Controller;
use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function register(RegisterRequest $request, RegisterUser $register): JsonResponse
    {
        $result = $register->handle(
            $request->string('name')->toString(),
            $request->string('email')->toString(),
            $request->string('password')->toString(),
        );

        return response()->json($this->tokenPayload($result['user'], $result['token']), 201);
    }

    public function login(LoginRequest $request, LoginUser $login): JsonResponse
    {
        $result = $login->handle(
            $request->string('email')->toString(),
            $request->string('password')->toString(),
        );

        return response()->json($this->tokenPayload($result['user'], $result['token']));
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()?->currentAccessToken()?->delete();

        return response()->json(['ok' => true]);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json(['user' => $this->userPayload($request->user())]);
    }

    /**
     * @return array{token: string, user: array<string, mixed>}
     */
    private function tokenPayload(User $user, string $token): array
    {
        return [
            'token' => $token,
            'user' => $this->userPayload($user),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function userPayload(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'plan' => $user->plan,
        ];
    }
}
