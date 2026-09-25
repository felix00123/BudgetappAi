<?php

namespace Tests\Feature;

use App\Models\BudgetRecord;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class CloudAccountTest extends TestCase
{
    use RefreshDatabase;

    public function test_register_seeds_defaults_and_users_cannot_see_each_other(): void
    {
        $alice = $this->postJson('/api/v1/auth/register', [
            'name' => 'Alice',
            'email' => 'alice@example.com',
            'password' => 'password1',
            'password_confirmation' => 'password1',
        ])->assertCreated();

        $bob = $this->postJson('/api/v1/auth/register', [
            'name' => 'Bob',
            'email' => 'bob@example.com',
            'password' => 'password1',
            'password_confirmation' => 'password1',
        ])->assertCreated();

        $alice->assertJsonPath('user.plan', 'standard');
        $this->assertNotSame($alice->json('token'), $bob->json('token'));
        $this->assertNotSame($alice->json('user.id'), $bob->json('user.id'));

        $this->asToken($alice->json('token'))
            ->postJson('/api/v1/sync/push', [
                'transactions' => [[
                    'id' => 'tx-alice',
                    'title' => 'Salary',
                    'amount' => 1000,
                    'type' => 'income',
                    'categoryId' => 'cat_salary',
                    'accountId' => 'acc_bank',
                    'date' => '2026-09-01T00:00:00Z',
                    'updatedAt' => '2026-09-01T00:00:00Z',
                ]],
            ])->assertOk();

        $alicePull = $this->asToken($alice->json('token'))
            ->getJson('/api/v1/sync/pull')
            ->assertOk();

        $bobPull = $this->asToken($bob->json('token'))
            ->getJson('/api/v1/sync/pull')
            ->assertOk();

        $aliceIds = collect($alicePull->json('transactions'))->pluck('id');
        $bobIds = collect($bobPull->json('transactions'))->pluck('id');

        $this->assertTrue($aliceIds->contains('tx-alice'), json_encode($alicePull->json('transactions')));
        $this->assertFalse($bobIds->contains('tx-alice'));
        $this->assertNotEmpty($alicePull->json('categories'));
        $this->assertNotEmpty($bobPull->json('accounts'));
    }

    public function test_newer_update_wins_and_older_push_is_ignored(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('mobile')->plainTextToken;

        $this->asToken($token)->postJson('/api/v1/sync/push', [
            'accounts' => [[
                'id' => 'acc_cash',
                'name' => 'Newer',
                'type' => 'cash',
                'initialBalance' => 0,
                'colorValue' => 1,
                'updatedAt' => '2026-09-02T00:00:00Z',
            ]],
        ])->assertOk();

        $this->asToken($token)->postJson('/api/v1/sync/push', [
            'accounts' => [[
                'id' => 'acc_cash',
                'name' => 'Older',
                'type' => 'cash',
                'initialBalance' => 0,
                'colorValue' => 1,
                'updatedAt' => '2026-09-01T00:00:00Z',
            ]],
        ])->assertOk();

        $pull = $this->asToken($token)->getJson('/api/v1/sync/pull?since=2026-09-01T12:00:00Z');
        $cash = collect($pull->json('accounts'))->firstWhere('id', 'acc_cash');

        $this->assertNotNull($cash, json_encode($pull->json()));
        $this->assertSame('Newer', $cash['name']);
    }

    public function test_hosted_model_hides_the_server_key(): void
    {
        config([
            'services.ai.base_url' => 'http://models.test/v1',
            'services.ai.api_key' => 'secret-server-key',
            'services.ai.model' => 'budget-model',
        ]);

        Http::fake([
            'models.test/*' => Http::response([
                'choices' => [
                    ['message' => ['content' => 'save more']],
                ],
            ]),
        ]);

        $user = User::factory()->create();

        $this->actingAs($user)
            ->postJson('/api/v1/ai/complete', [
                'systemPrompt' => 'advisor',
                'userPrompt' => 'how am I doing?',
            ])
            ->assertOk()
            ->assertJsonPath('content', 'save more')
            ->assertDontSee('secret-server-key');

        Http::assertSent(function ($request) {
            return $request->hasHeader('Authorization', 'Bearer secret-server-key')
                && $request['model'] === 'budget-model';
        });

        $this->assertSame(0, BudgetRecord::query()->count());
    }

    private function asToken(string $token): static
    {
        $this->app['auth']->forgetGuards();

        return $this->withToken($token);
    }
}
