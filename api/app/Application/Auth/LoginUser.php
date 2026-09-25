<?php

namespace App\Application\Auth;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class LoginUser
{
    /**
     * @return array{user: User, token: string}
     */
    public function handle(string $email, string $password): array
    {
        $user = User::query()->where('email', $email)->first();

        if ($user === null || ! Hash::check($password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['These credentials do not match our records.'],
            ]);
        }

        return [
            'user' => $user,
            'token' => $user->createToken('mobile')->plainTextToken,
        ];
    }
}
