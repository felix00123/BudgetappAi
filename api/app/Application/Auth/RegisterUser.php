<?php

namespace App\Application\Auth;

use App\Domain\Sync\SyncStore;
use App\Models\User;

class RegisterUser
{
    public function __construct(private readonly SyncStore $sync) {}

    /**
     * @return array{user: User, token: string}
     */
    public function handle(string $name, string $email, string $password): array
    {
        $user = User::query()->create([
            'name' => $name,
            'email' => $email,
            'password' => $password,
            'plan' => 'standard',
        ]);

        $this->sync->seedDefaults($user->id);

        return [
            'user' => $user,
            'token' => $user->createToken('mobile')->plainTextToken,
        ];
    }
}
