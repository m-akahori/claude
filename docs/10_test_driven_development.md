# 9. テスト駆動開発

## 9.1 TDD基本原則

### 9.1.1 Red-Green-Refactor サイクル

1. **Red**: 失敗するテストを書く
2. **Green**: テストを最小限のコードで通す
3. **Refactor**: コードをリファクタリングして改善する

```php
// 1. Red: 失敗するテストを書く
class UserServiceTest extends TestCase
{
    public function test_create_user_with_valid_data(): void
    {
        $userData = [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123'
        ];
        
        $userService = new UserService();
        $user = $userService->createUser($userData);
        
        $this->assertInstanceOf(User::class, $user);
        $this->assertEquals('John Doe', $user->name);
        $this->assertEquals('john@example.com', $user->email);
        $this->assertTrue(Hash::check('password123', $user->password));
    }
}

// 2. Green: 最小限のコードでテストを通す
class UserService
{
    public function createUser(array $data): User
    {
        $user = new User();
        $user->name = $data['name'];
        $user->email = $data['email'];
        $user->password = Hash::make($data['password']);
        $user->save();
        
        return $user;
    }
}

// 3. Refactor: コードを改善
class UserService
{
    public function __construct(
        private readonly UserRepositoryInterface $userRepository,
        private readonly UserValidatorInterface $validator
    ) {}
    
    public function createUser(array $data): User
    {
        $this->validator->validate($data);
        
        $user = new User([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => Hash::make($data['password'])
        ]);
        
        return $this->userRepository->save($user);
    }
}
```

### 9.1.2 FIRST 原則

- **Fast**: テストは高速で実行されるべき
- **Independent**: テストは他のテストに依存しない
- **Repeatable**: 任意の環境で繰り返し実行可能
- **Self-Validating**: テスト結果はBooleanで明確
- **Timely**: テストはタイムリーに書かれる

```php
// Good: FIRST原則に従ったテスト
class PostServiceTest extends TestCase
{
    use RefreshDatabase;
    
    // Fast: データベースを使わず、Mockで高速化
    public function test_can_create_post(): void
    {
        $repository = $this->createMock(PostRepositoryInterface::class);
        $repository->expects($this->once())
                  ->method('save')
                  ->willReturn(new Post(['title' => 'Test Post']));
        
        $service = new PostService($repository);
        $post = $service->createPost(['title' => 'Test Post']);
        
        $this->assertEquals('Test Post', $post->title);
    }
    
    // Independent: 他のテストに依存しない
    public function test_validates_post_data(): void
    {
        $service = new PostService(
            $this->createMock(PostRepositoryInterface::class)
        );
        
        $this->expectException(ValidationException::class);
        $service->createPost([]); // 空のデータでバリデーションエラー
    }
    
    // Self-Validating: 結果が明確
    public function test_throws_exception_for_invalid_data(): void
    {
        $service = new PostService(
            $this->createMock(PostRepositoryInterface::class)
        );
        
        $this->expectException(InvalidArgumentException::class);
        $this->expectExceptionMessage('タイトルは必須です');
        
        $service->createPost(['title' => '']);
    }
}

// Bad: FIRST原則違反の例
class BadPostServiceTest extends TestCase
{
    private static $createdPostId;
    
    // 依存関係あり（Independent違反）
    public function test_create_post(): void
    {
        $service = new PostService();
        $post = $service->createPost(['title' => 'Test']);
        
        self::$createdPostId = $post->id; // 他のテストで使用
        $this->assertNotNull($post->id);
    }
    
    // 上のテストに依存（Independent違反）
    public function test_update_post(): void
    {
        $service = new PostService();
        $post = $service->updatePost(self::$createdPostId, ['title' => 'Updated']);
        
        $this->assertEquals('Updated', $post->title);
    }
}
```

## 9.2 テスト戦略

### 9.2.1 単体テスト

```php
// 単体テスト: 単一クラスのメソッドをテスト
class UserValidatorTest extends TestCase
{
    private UserValidator $validator;
    
    protected function setUp(): void
    {
        parent::setUp();
        $this->validator = new UserValidator();
    }
    
    public function test_validates_required_fields(): void
    {
        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('名前は必須です');
        
        $this->validator->validate(['email' => 'test@example.com']);
    }
    
    public function test_validates_email_format(): void
    {
        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('正しいメールアドレスを入力してください');
        
        $this->validator->validate([
            'name' => 'John Doe',
            'email' => 'invalid-email'
        ]);
    }
    
    public function test_validates_password_strength(): void
    {
        $this->expectException(ValidationException::class);
        
        $this->validator->validate([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => '123' // 弱いパスワード
        ]);
    }
    
    public function test_passes_validation_with_valid_data(): void
    {
        $validData = [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'SecurePassword123!'
        ];
        
        // 例外が投げられないことを確認
        $this->validator->validate($validData);
        $this->assertTrue(true); // ここまで到達したら成功
    }
    
    /**
     * @dataProvider invalidEmailProvider
     */
    public function test_rejects_invalid_emails(string $email): void
    {
        $this->expectException(ValidationException::class);
        
        $this->validator->validate([
            'name' => 'John Doe',
            'email' => $email,
            'password' => 'SecurePassword123!'
        ]);
    }
    
    public static function invalidEmailProvider(): array
    {
        return [
            [''],
            ['invalid'],
            ['@example.com'],
            ['test@'],
            ['test..test@example.com'],
            ['test@example'],
        ];
    }
}
```

### 9.2.2 統合テスト

```php
// 統合テスト: 複数のコンポーネントを組み合わせたテスト
class PostServiceIntegrationTest extends TestCase
{
    use RefreshDatabase;
    
    private PostService $postService;
    private User $user;
    
    protected function setUp(): void
    {
        parent::setUp();
        
        // 実際のサービスを使用（Mockなし）
        $this->postService = app(PostService::class);
        $this->user = User::factory()->create();
    }
    
    public function test_creates_post_with_category_and_tags(): void
    {
        $category = Category::factory()->create();
        $tags = Tag::factory(3)->create();
        
        $postData = [
            'title' => 'Integration Test Post',
            'content' => 'This is a test post content.',
            'category_id' => $category->id,
            'tag_ids' => $tags->pluck('id')->toArray(),
            'user_id' => $this->user->id,
        ];
        
        $post = $this->postService->createPost($postData);
        
        // データベースに保存されていることを確認
        $this->assertDatabaseHas('posts', [
            'id' => $post->id,
            'title' => 'Integration Test Post',
            'user_id' => $this->user->id,
            'category_id' => $category->id,
        ]);
        
        // リレーションが正しく設定されていることを確認
        $post = $post->fresh(['category', 'tags', 'user']);
        $this->assertEquals($category->name, $post->category->name);
        $this->assertCount(3, $post->tags);
        $this->assertEquals($this->user->name, $post->user->name);
    }
    
    public function test_publishes_post_and_sends_notifications(): void
    {
        Notification::fake();
        
        $post = Post::factory()->draft()->for($this->user)->create();
        $subscribers = User::factory(5)->create();
        
        // 購読者を設定
        foreach ($subscribers as $subscriber) {
            $subscriber->subscriptions()->attach($this->user->id);
        }
        
        $publishedPost = $this->postService->publishPost($post->id);
        
        // 投稿が公開されたことを確認
        $this->assertEquals('published', $publishedPost->status);
        $this->assertNotNull($publishedPost->published_at);
        
        // 購読者に通知が送られたことを確認
        Notification::assertSentTo(
            $subscribers,
            PostPublishedNotification::class
        );
    }
}
```

### 9.2.3 E2Eテスト

```php
// E2Eテスト: ユーザーの操作をシミュレート
class CreatePostE2ETest extends TestCase
{
    use RefreshDatabase;
    
    public function test_user_can_create_and_publish_post_via_web_interface(): void
    {
        // ユーザー作成
        $user = User::factory()->create();
        $category = Category::factory()->create();
        $tags = Tag::factory(2)->create();
        
        // 1. ログイン
        $response = $this->postJson('/api/auth/login', [
            'email' => $user->email,
            'password' => 'password',
        ]);
        
        $response->assertOk();
        $token = $response->json('token');
        
        // 2. 投稿作成
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $token,
        ])->postJson('/api/posts', [
            'title' => 'E2E Test Post',
            'content' => 'This is an E2E test post.',
            'category_id' => $category->id,
            'tag_ids' => $tags->pluck('id')->toArray(),
            'status' => 'draft',
        ]);
        
        $response->assertCreated();
        $postId = $response->json('data.id');
        
        // 3. 投稿詳細取得
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $token,
        ])->getJson("/api/posts/{$postId}");
        
        $response->assertOk()
                 ->assertJson([
                     'data' => [
                         'title' => 'E2E Test Post',
                         'status' => 'draft',
                         'category' => [
                             'name' => $category->name
                         ],
                     ]
                 ]);
        
        // 4. 投稿公開
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $token,
        ])->putJson("/api/posts/{$postId}/publish");
        
        $response->assertOk();
        
        // 5. 公開された投稿が一覧に表示されることを確認
        $response = $this->getJson('/api/posts');
        
        $response->assertOk()
                 ->assertJsonPath('data.0.title', 'E2E Test Post')
                 ->assertJsonPath('data.0.status', 'published');
    }
    
    public function test_unauthorized_user_cannot_create_post(): void
    {
        $response = $this->postJson('/api/posts', [
            'title' => 'Unauthorized Post',
            'content' => 'This should fail.',
        ]);
        
        $response->assertUnauthorized();
    }
    
    public function test_user_cannot_publish_other_users_post(): void
    {
        $author = User::factory()->create();
        $otherUser = User::factory()->create();
        
        $post = Post::factory()->draft()->for($author)->create();
        
        $response = $this->actingAs($otherUser)
                         ->putJson("/api/posts/{$post->id}/publish");
        
        $response->assertForbidden();
    }
}
```

## 9.3 テストツール

### 9.3.1 PHPUnit（バックエンド）

```xml
<!-- phpunit.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
         bootstrap="vendor/autoload.php"
         colors="true"
>
    <testsuites>
        <testsuite name="Unit">
            <directory>tests/Unit</directory>
        </testsuite>
        <testsuite name="Feature">
            <directory>tests/Feature</directory>
        </testsuite>
    </testsuites>
    <source>
        <include>
            <directory>app</directory>
        </include>
    </source>
    <php>
        <env name="APP_ENV" value="testing"/>
        <env name="APP_MAINTENANCE_DRIVER" value="file"/>
        <env name="BCRYPT_ROUNDS" value="4"/>
        <env name="CACHE_STORE" value="array"/>
        <!-- DB設定はコメントアウト（デフォルトのMariaDB使用） -->
        <!-- <env name="DB_CONNECTION" value="sqlite"/> -->
        <!-- <env name="DB_DATABASE" value=":memory:"/> -->
        <env name="MAIL_MAILER" value="array"/>
        <env name="PULSE_ENABLED" value="false"/>
        <env name="QUEUE_CONNECTION" value="sync"/>
        <env name="SESSION_DRIVER" value="array"/>
        <env name="TELESCOPE_ENABLED" value="false"/>
    </php>
</phpunit>

// テストヘルパークラス
abstract class TestCase extends BaseTestCase
{
    use CreatesApplication;
    
    protected function setUp(): void
    {
        parent::setUp();
        
        // テスト用の初期化
        $this->withoutMiddleware(\App\Http\Middleware\VerifyCsrfToken::class);
    }
    
    protected function authenticatedUser(array $attributes = []): User
    {
        $user = User::factory()->create($attributes);
        $this->actingAs($user);
        return $user;
    }
    
    protected function createAdminUser(): User
    {
        return User::factory()->admin()->create();
    }
    
    protected function assertApiSuccess(TestResponse $response, int $status = 200): void
    {
        $response->assertStatus($status)
                 ->assertJsonStructure([
                     'data',
                     'message',
                     'status'
                 ]);
    }
    
    protected function assertApiError(TestResponse $response, int $status = 400): void
    {
        $response->assertStatus($status)
                 ->assertJsonStructure([
                     'errors',
                     'message',
                     'status'
                 ]);
    }
}
```

### 9.3.2 Vitest（フロントエンド）

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

export default defineConfig({
  plugins: [vue()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./tests/setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'tests/',
        '*.config.*',
      ]
    }
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, './resources/js'),
    }
  }
})

// tests/setup.ts
import { config } from '@vue/test-utils'
import { vi } from 'vitest'

// グローバルコンポーネントのモック
config.global.mocks = {
  $t: (key: string) => key, // i18nモック
}

// グローバルモック
vi.mock('@/api/client', () => ({
  apiClient: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    delete: vi.fn(),
  }
}))

// コンポーネントテスト例
// tests/components/UserForm.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { nextTick } from 'vue'
import UserForm from '@/components/UserForm.vue'
import { createTestingPinia } from '@pinia/testing'

describe('UserForm', () => {
  let wrapper: any
  
  beforeEach(() => {
    wrapper = mount(UserForm, {
      global: {
        plugins: [
          createTestingPinia({
            createSpy: vi.fn,
          })
        ]
      },
      props: {
        user: {
          id: 1,
          name: 'John Doe',
          email: 'john@example.com'
        },
        isEditable: true
      }
    })
  })
  
  it('renders user form with initial data', () => {
    expect(wrapper.find('[data-testid="user-name"]').element.value).toBe('John Doe')
    expect(wrapper.find('[data-testid="user-email"]').element.value).toBe('john@example.com')
  })
  
  it('validates required fields', async () => {
    await wrapper.find('[data-testid="user-name"]').setValue('')
    await wrapper.find('form').trigger('submit')
    
    expect(wrapper.find('[data-testid="name-error"]').text()).toBe('名前は必須です')
  })
  
  it('emits update event on successful submit', async () => {
    const mockApiCall = vi.fn().mockResolvedValue({
      data: { id: 1, name: 'Updated Name', email: 'john@example.com' }
    })
    
    vi.mock('@/api/users', () => ({
      updateUser: mockApiCall
    }))
    
    await wrapper.find('[data-testid="user-name"]').setValue('Updated Name')
    await wrapper.find('form').trigger('submit')
    await nextTick()
    
    expect(wrapper.emitted('update')).toBeTruthy()
    expect(wrapper.emitted('update')[0][0]).toEqual(
      expect.objectContaining({ name: 'Updated Name' })
    )
  })
})
```

## 9.4 テストカバレッジ

### 9.4.1 カバレッジ目標

- **単体テスト**: 90%以上
- **統合テスト**: 80%以上
- **全体**: 85%以上
- **重要なビジネスロジック**: 95%以上

### 9.4.2 カバレッジ測定

```bash
# PHP カバレッジ測定（ローカル環境）
php artisan test --coverage --min=100

# PHP カバレッジ測定（Docker環境）
docker compose exec php-fpm php artisan test --coverage --min=100

# JavaScript カバレッジ測定
npm run test:coverage

# カバレッジレポート生成（ローカル環境）
php artisan test --coverage-html coverage-report

# カバレッジレポート生成（Docker環境）
docker compose exec php-fpm php artisan test --coverage-html coverage-report
```

### 9.4.3 PCOV設定

本プロジェクトではカバレッジ測定にPCOVを使用しています。

**Dockerfileへの追加（既に設定済み）:**
```dockerfile
# Install PCOV extension for code coverage
RUN pecl install pcov && docker-php-ext-enable pcov
```

**PCOV確認コマンド:**
```bash
# PCOVがインストールされているか確認
docker compose exec php-fpm php -m | grep pcov
```

**カバレッジレポートの確認:**
- HTMLレポート: `coverage-report/index.html` をブラウザで開く
- レポートはgitignoreに追加済み（`/coverage-report`）

```php
// カバレッジ確認コマンド
class CheckCoverageCommand extends Command
{
    protected $signature = 'test:coverage-check {threshold=85}';
    protected $description = 'テストカバレッジを確認し、闾値を下回った場合はエラー';
    
    public function handle(): int
    {
        $threshold = (int) $this->argument('threshold');
        
        $process = Process::run([
            'php', 'artisan', 'test', '--coverage-text', '--colors=never'
        ]);
        
        if (!$process->successful()) {
            $this->error('テスト実行に失敗しました');
            return 1;
        }
        
        $output = $process->output();
        
        // カバレッジパーセンテージを抽出
        if (preg_match('/Lines:\s+(\d+\.\d+)%/', $output, $matches)) {
            $coverage = (float) $matches[1];
            
            $this->info("現在のカバレッジ: {$coverage}%");
            
            if ($coverage < $threshold) {
                $this->error("カバレッジが目標に達していません: {$coverage}% < {$threshold}%");
                return 1;
            }
            
            $this->info('カバレッジ目標を達成しています!');
            return 0;
        }
        
        $this->error('カバレッジ情報を取得できませんでした');
        return 1;
    }
}
```

## 9.5 パフォーマンステスト

### 9.5.1 負荷テスト

```php
// 負荷テストコマンド
class LoadTestCommand extends Command
{
    protected $signature = 'test:load {endpoint} {--concurrent=10} {--requests=100}';
    protected $description = 'APIエンドポイントの負荷テストを実行';
    
    public function handle(): void
    {
        $endpoint = $this->argument('endpoint');
        $concurrent = $this->option('concurrent');
        $requests = $this->option('requests');
        
        $this->info("負荷テスト開始: {$endpoint}");
        $this->info("同時リクエスト数: {$concurrent}");
        $this->info("総リクエスト数: {$requests}");
        
        $startTime = microtime(true);
        $responses = [];
        
        // 並列リクエスト実行
        $promises = [];
        for ($i = 0; $i < $requests; $i++) {
            $promises[] = Http::async()->get(config('app.url') . $endpoint);
            
            // 同時リクエスト数を制限
            if (count($promises) >= $concurrent || $i === $requests - 1) {
                $batchResponses = Promise::settle($promises)->wait();
                $responses = array_merge($responses, $batchResponses);
                $promises = [];
            }
        }
        
        $endTime = microtime(true);
        $totalTime = $endTime - $startTime;
        
        // 結果解析
        $successCount = 0;
        $errorCount = 0;
        $responseTimes = [];
        
        foreach ($responses as $response) {
            if ($response['state'] === 'fulfilled') {
                $httpResponse = $response['value'];
                if ($httpResponse->successful()) {
                    $successCount++;
                } else {
                    $errorCount++;
                }
                // レスポンスタイムを記録（実際にはタイマーが必要）
            } else {
                $errorCount++;
            }
        }
        
        // 結果表示
        $this->info('\n=== 負荷テスト結果 ===');
        $this->info("総実行時間: " . round($totalTime, 2) . '秒');
        $this->info("成功: {$successCount}");
        $this->info("失敗: {$errorCount}");
        $this->info('成功率: ' . round(($successCount / $requests) * 100, 2) . '%');
        $this->info('RPS: ' . round($requests / $totalTime, 2));
        
        if ($errorCount > 0) {
            $this->warn('エラーが発生しています。サーバーのパフォーマンスを確認してください。');
        }
    }
}
```

### 9.5.2 メモリ使用量テスト

```php
class MemoryUsageTest extends TestCase
{
    public function test_bulk_user_creation_memory_usage(): void
    {
        $initialMemory = memory_get_usage(true);
        
        // 大量のユーザーを作成
        $users = User::factory(1000)->make();
        
        $peakMemory = memory_get_peak_usage(true);
        $memoryUsed = $peakMemory - $initialMemory;
        
        // メモリ使用量が闾値を超えていないことを確認
        $maxMemoryMB = 50; // 50MBを上限とする
        $memoryUsedMB = $memoryUsed / 1024 / 1024;
        
        $this->assertLessThan(
            $maxMemoryMB,
            $memoryUsedMB,
            "メモリ使用量が上限を超えています: {$memoryUsedMB}MB > {$maxMemoryMB}MB"
        );
    }
    
    public function test_large_dataset_processing_memory_efficiency(): void
    {
        $initialMemory = memory_get_usage(true);
        
        // 大量のデータをチャンクで処理
        User::factory(5000)->create();
        
        $processedCount = 0;
        $chunkSize = 100;
        
        User::chunk($chunkSize, function ($users) use (&$processedCount) {
            foreach ($users as $user) {
                // 何らかの処理
                $user->email = strtolower($user->email);
                $processedCount++;
            }
            
            // メモリリークを防ぐために明示的に解放
            unset($users);
        });
        
        $peakMemory = memory_get_peak_usage(true);
        $memoryUsed = $peakMemory - $initialMemory;
        $memoryUsedMB = $memoryUsed / 1024 / 1024;
        
        // メモリ使用量が線形に増加していないことを確認
        $this->assertLessThan(
            100, // 100MBを上限とする
            $memoryUsedMB,
            "チャンク処理でメモリリークが発生している可能性があります: {$memoryUsedMB}MB"
        );
        
        $this->assertEquals(5000, $processedCount);
    }
}
```

## 9.6 プロジェクト実例

本プロジェクトで実装したテストコードの実例を紹介します。

### 9.6.1 Repository層のテスト

```php
// tests/Unit/Repositories/ContactRepositoryTest.php
namespace Tests\Unit\Repositories;

use App\Repositories\ContactRepository;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class ContactRepositoryTest extends TestCase
{
    private ContactRepository $repository;

    protected function setUp(): void
    {
        parent::setUp();
        $this->repository = new ContactRepository;
    }

    public function test_save_logs_contact_data_and_returns_true(): void
    {
        Log::shouldReceive('info')
            ->once()
            ->with('Contact form submitted', [
                'name' => 'Test User',
                'email' => 'test@example.com',
                'content' => 'Test content',
            ]);

        $data = [
            'name' => 'Test User',
            'email' => 'test@example.com',
            'content' => 'Test content',
        ];

        $result = $this->repository->save($data);

        $this->assertTrue($result);
    }

    public function test_find_by_email_returns_empty_array(): void
    {
        $result = $this->repository->findByEmail('test@example.com');

        $this->assertIsArray($result);
        $this->assertEmpty($result);
    }
}
```

### 9.6.2 Service層のテスト

```php
// tests/Unit/Services/ContactServiceTest.php
namespace Tests\Unit\Services;

use App\Mail\ContactMail;
use App\Repositories\Interfaces\ContactRepositoryInterface;
use App\Services\ContactService;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class ContactServiceTest extends TestCase
{
    private ContactService $service;
    private ContactRepositoryInterface $repository;

    protected function setUp(): void
    {
        parent::setUp();

        // Mockリポジトリを作成
        $this->repository = $this->createMock(ContactRepositoryInterface::class);
        $this->service = new ContactService($this->repository);
    }

    public function test_send_contact_saves_data_and_sends_email_in_non_production(): void
    {
        // リポジトリのsaveメソッドが1回呼ばれることを期待
        $this->repository->expects($this->once())
            ->method('save')
            ->with([
                'name' => 'Test User',
                'email' => 'test@example.com',
                'content' => 'Test content',
            ])
            ->willReturn(true);

        // Mailファサードのモック
        Mail::shouldReceive('to')
            ->once()
            ->with('test@example.com')
            ->andReturnSelf();

        Mail::shouldReceive('send')
            ->once()
            ->with(\Mockery::type(ContactMail::class));

        $data = [
            'name' => 'Test User',
            'email' => 'test@example.com',
            'content' => 'Test content',
        ];

        $result = $this->service->sendContact($data);

        $this->assertTrue($result);
    }

    protected function tearDown(): void
    {
        \Mockery::close();
        parent::tearDown();
    }
}
```

### 9.6.3 Request層のテスト

```php
// tests/Unit/Requests/SendContactRequestTest.php
namespace Tests\Unit\Requests;

use App\Http\Requests\SendContactRequest;
use Illuminate\Support\Facades\Validator;
use Tests\TestCase;

class SendContactRequestTest extends TestCase
{
    private SendContactRequest $request;

    protected function setUp(): void
    {
        parent::setUp();
        $this->request = new SendContactRequest;
    }

    public function test_authorize_returns_true(): void
    {
        $this->assertTrue($this->request->authorize());
    }

    public function test_rules_returns_correct_validation_rules(): void
    {
        $rules = $this->request->rules();

        $this->assertArrayHasKey('name', $rules);
        $this->assertArrayHasKey('email', $rules);
        $this->assertArrayHasKey('content', $rules);

        $this->assertEquals(['required', 'string', 'max:50'], $rules['name']);
        $this->assertEquals(['required', 'email'], $rules['email']);
        $this->assertEquals(['required', 'string', 'max:1000'], $rules['content']);
    }

    public function test_validation_fails_when_name_is_missing(): void
    {
        $data = [
            'email' => 'test@example.com',
            'content' => 'This is a test content',
        ];

        $validator = Validator::make($data, $this->request->rules(), $this->request->messages());

        $this->assertTrue($validator->fails());
        $this->assertEquals('お名前は必須です。', $validator->errors()->first('name'));
    }
}
```

### 9.6.4 Controller層のテスト

```php
// tests/Feature/Controllers/ContactControllerTest.php
namespace Tests\Feature\Controllers;

use App\Services\ContactService;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class ContactControllerTest extends TestCase
{
    public function test_send_returns_success_response_with_valid_data(): void
    {
        Mail::fake();

        $data = [
            'name' => 'Test User',
            'email' => 'test@example.com',
            'content' => 'This is a test content',
        ];

        $response = $this->postJson('/api/contact', $data);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'メールを送信しました',
            ]);
    }

    public function test_send_returns_error_when_service_throws_exception(): void
    {
        $this->mock(ContactService::class, function ($mock) {
            $mock->shouldReceive('sendContact')
                ->once()
                ->andThrow(new \Exception('Test exception'));
        });

        $data = [
            'name' => 'Test User',
            'email' => 'test@example.com',
            'content' => 'This is a test content',
        ];

        $response = $this->postJson('/api/contact', $data);

        $response->assertStatus(500)
            ->assertJson([
                'success' => false,
                'message' => 'メール送信に失敗しました: Test exception',
            ]);
    }
}
```

### 9.6.5 テスト実行とカバレッジ確認

```bash
# 全テスト実行
docker compose exec php-fpm php artisan test

# カバレッジ付きテスト実行
docker compose exec php-fpm php artisan test --coverage --min=100

# HTMLカバレッジレポート生成
docker compose exec php-fpm php artisan test --coverage-html coverage-report

# カバレッジレポートの確認
open coverage-report/index.html
```

**実行結果例:**
```
Tests:    29 passed (69 assertions)
Duration: 2.64s

Http/Controllers/ContactController .................................. 100.0%
Http/Requests/SendContactRequest .................................... 100.0%
Mail/ContactMail .................................................... 100.0%
Models/User ......................................................... 100.0%
Repositories/ContactRepository ...................................... 100.0%
Services/ContactService ............................................. 100.0%
────────────────────────────────────────────────────────────────────────────
                                                                Total: 100.0%
```