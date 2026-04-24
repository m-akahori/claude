# 4. PHP/Laravel コーディングルール

## 4.1 PHP基本ルール

### 4.1.1 PHP 8.2対応
- **最新機能の活用**：Readonly Properties、Enums、Union Types等を積極的に使用
- **非推奨機能の回避**：非推奨の関数や構文を使用しない
- **パフォーマンス最適化**：PHP 8.2のパフォーマンス改善を活用

### 4.1.2 型宣言・戻り値型
```php
// 必須: 明示的な型宣言
class UserService
{
    public function __construct(
        private readonly UserRepository $userRepository,
        private readonly EmailService $emailService
    ) {}

    public function createUser(string $name, string $email): User
    {
        $user = new User($name, $email);
        $this->userRepository->save($user);
        
        return $user;
    }

    public function findUserById(int $id): ?User
    {
        return $this->userRepository->findById($id);
    }

    public function getUserList(array $filters = []): Collection
    {
        return $this->userRepository->findByFilters($filters);
    }
}
```

### 4.1.3 コンストラクタプロパティプロモーション
```php
// Good: コンストラクタプロパティプロモーションを使用
class PaymentService
{
    public function __construct(
        private readonly PaymentGateway $gateway,
        private readonly Logger $logger
    ) {}
}

// Bad: 空のコンストラクタ
class EmptyService
{
    public function __construct()
    {
        // 空のコンストラクタは作らない
    }
}
```

### 4.1.4 制御構造とカッコ
```php
// Good: 必ず中カッコを使用
if ($user->isActive()) {
    $this->processActiveUser($user);
} else {
    $this->processInactiveUser($user);
}

foreach ($users as $user) {
    $this->processUser($user);
}

while ($this->hasMoreData()) {
    $this->processNextBatch();
}

// Bad: 中カッコなし
if ($user->isActive())
    $this->processActiveUser($user);  // NG
```

## 4.2 Laravel 11 ルール

### 4.2.1 ディレクトリ構造（bootstrap/app.php中心）
```php
// bootstrap/app.php - Laravel 11の中心設定ファイル
return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->web(append: [
            \App\Http\Middleware\HandleInertiaRequests::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        //
    })
    ->create();
```

### 4.2.2 Artisanコマンド活用
```bash
# モデル作成時は必要なファイルを同時作成
php artisan make:model User -mfc
# -m: migration, -f: factory, -c: controller

# Form Request作成
php artisan make:request StoreUserRequest

# サービスクラス作成（Laravel 11）
php artisan make:class Services/UserService

# コマンド作成（自動登録）
php artisan make:command ProcessPayments
```

### 4.2.3 Eloquent ORM使用
```php
// Good: Eloquentとリレーションを活用
class User extends Model
{
    protected $fillable = ['name', 'email', 'password'];
    
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'is_active' => 'boolean',
        ];
    }
    
    // リレーションに型ヒントを記載
    public function posts(): HasMany
    {
        return $this->hasMany(Post::class);
    }
    
    public function profile(): HasOne
    {
        return $this->hasOne(Profile::class);
    }
}

// N+1問題の対策
class PostController extends Controller
{
    public function index(): Response
    {
        $posts = Post::with('user', 'comments.user')
            ->latest()
            ->paginate(10);
            
        return response()->json($posts);
    }
}

// Bad: DB::を使用した生のSQL
DB::select('SELECT * FROM users WHERE active = 1'); // 避ける

// Good: Model::query()を使用
User::query()->where('active', true)->get();
```

## 4.3 依存性の注入

### 4.3.1 DIコンテナ活用
```php
// Service Providerでのサービス登録
class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(PaymentGateway::class, StripeGateway::class);
        
        $this->app->bind(UserRepositoryInterface::class, EloquentUserRepository::class);
    }
}

// ControllerでのDI
class UserController extends Controller
{
    public function __construct(
        private readonly UserService $userService,
        private readonly UserRepositoryInterface $userRepository
    ) {}
    
    public function store(StoreUserRequest $request): JsonResponse
    {
        $user = $this->userService->createUser($request->validated());
        
        return response()->json($user, 201);
    }
}
```

### 4.3.2 オートワイヤリング
```php
// コンストラクタインジェクションで自動解決
class OrderService
{
    public function __construct(
        private readonly PaymentService $paymentService,
        private readonly InventoryService $inventoryService,
        private readonly EmailService $emailService
    ) {}
    
    public function processOrder(Order $order): void
    {
        $this->inventoryService->reserve($order->items);
        $this->paymentService->charge($order->total);
        $this->emailService->sendConfirmation($order->user->email);
    }
}
```

### 4.3.3 インターフェース活用
```php
// インターフェース定義
interface PaymentGatewayInterface
{
    public function charge(int $amount, string $token): PaymentResult;
    public function refund(string $transactionId, int $amount): RefundResult;
}

// 具体実装
class StripeGateway implements PaymentGatewayInterface
{
    public function charge(int $amount, string $token): PaymentResult
    {
        // Stripe固有の実装
    }
    
    public function refund(string $transactionId, int $amount): RefundResult
    {
        // Stripe固有の実装
    }
}

// テスト用のMock
class MockPaymentGateway implements PaymentGatewayInterface
{
    public function charge(int $amount, string $token): PaymentResult
    {
        return new PaymentResult(true, 'mock_transaction_id');
    }
    
    public function refund(string $transactionId, int $amount): RefundResult
    {
        return new RefundResult(true);
    }
}
```

## 4.4 モデル・マイグレーション

### 4.4.1 モデル定義
```php
class Post extends Model
{
    protected $fillable = [
        'title',
        'slug',
        'content',
        'status',
        'published_at',
        'user_id',
    ];
    
    // Laravel 11: castsメソッドを推奨
    protected function casts(): array
    {
        return [
            'published_at' => 'datetime',
            'is_featured' => 'boolean',
            'metadata' => 'array',
            'status' => PostStatus::class, // Enumキャスト
        ];
    }
    
    // リレーションに型ヒントを必ず記載
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
    
    public function comments(): HasMany
    {
        return $this->hasMany(Comment::class);
    }
    
    public function tags(): BelongsToMany
    {
        return $this->belongsToMany(Tag::class);
    }
    
    // スコープの活用
    public function scopePublished(Builder $query): void
    {
        $query->where('status', PostStatus::Published)
              ->whereNotNull('published_at');
    }
    
    public function scopeByAuthor(Builder $query, User $author): void
    {
        $query->where('user_id', $author->id);
    }
}
```

### 4.4.2 リレーション定義
```php
// One-to-Many
class User extends Model
{
    public function posts(): HasMany
    {
        return $this->hasMany(Post::class);
    }
}

// Inverse One-to-Many
class Post extends Model
{
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

// Many-to-Many with Pivot
class Post extends Model
{
    public function tags(): BelongsToMany
    {
        return $this->belongsToMany(Tag::class, 'post_tags')
                    ->withPivot(['position', 'created_at'])
                    ->withTimestamps();
    }
}

// Polymorphic Relations
class Comment extends Model
{
    public function commentable(): MorphTo
    {
        return $this->morphTo();
    }
}

class Post extends Model
{
    public function comments(): MorphMany
    {
        return $this->morphMany(Comment::class, 'commentable');
    }
}
```

### 4.4.3 マイグレーション作成
```php
// Laravel 11: カラム修正時は全属性を再定義
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('posts', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->string('slug')->unique();
            $table->text('content');
            $table->enum('status', ['draft', 'published', 'archived'])
                  ->default('draft');
            $table->timestamp('published_at')->nullable();
            $table->boolean('is_featured')->default(false);
            $table->json('metadata')->nullable();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->timestamps();
            
            // インデックス
            $table->index(['status', 'published_at']);
            $table->index('user_id');
        });
    }
    
    public function down(): void
    {
        Schema::dropIfExists('posts');
    }
};

// カラム修正の例
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('posts', function (Blueprint $table) {
            // 既存カラムの修正時は全属性を再定義
            $table->string('title', 500)
                  ->nullable(false)
                  ->default('')
                  ->change();
        });
    }
};
```

## 4.5 コントローラー・バリデーション

### 4.5.1 Form Request使用
```php
// Form Requestクラス
class StorePostRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', Post::class);
    }
    
    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'slug' => ['required', 'string', 'unique:posts,slug', 'regex:/^[a-z0-9-]+$/'],
            'content' => ['required', 'string'],
            'status' => ['required', Rule::in(PostStatus::values())],
            'published_at' => ['nullable', 'date', 'after:now'],
            'tags' => ['array'],
            'tags.*' => ['integer', 'exists:tags,id'],
        ];
    }
    
    public function messages(): array
    {
        return [
            'title.required' => 'タイトルは必須です。',
            'slug.unique' => 'このURLは既に使用されています。',
            'slug.regex' => 'URLは英小文字、数字、ハイフンのみ使用できます。',
        ];
    }
    
    protected function prepareForValidation(): void
    {
        $this->merge([
            'slug' => Str::slug($this->slug ?: $this->title),
        ]);
    }
}

// Controllerでの使用
class PostController extends Controller
{
    public function __construct(
        private readonly PostService $postService
    ) {}
    
    public function store(StorePostRequest $request): JsonResponse
    {
        $post = $this->postService->createPost($request->validated());
        
        return response()->json(new PostResource($post), 201);
    }
}
```

### 4.5.2 API Resource使用
```php
// API Resource
class PostResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'slug' => $this->slug,
            'excerpt' => Str::limit($this->content, 150),
            'status' => $this->status->value,
            'published_at' => $this->published_at?->format('Y-m-d H:i:s'),
            'user' => new UserResource($this->whenLoaded('user')),
            'tags' => TagResource::collection($this->whenLoaded('tags')),
            'comments_count' => $this->when(
                $this->relationLoaded('comments'),
                fn() => $this->comments->count()
            ),
            'links' => [
                'self' => route('posts.show', $this->slug),
                'edit' => $this->when(
                    $request->user()?->can('update', $this->resource),
                    fn() => route('posts.edit', $this->slug)
                ),
            ],
        ];
    }
}

// Collection Resource
class PostCollection extends ResourceCollection
{
    public function toArray(Request $request): array
    {
        return [
            'data' => $this->collection,
            'meta' => [
                'total' => $this->total(),
                'per_page' => $this->perPage(),
                'current_page' => $this->currentPage(),
            ],
        ];
    }
}
```

## 4.6 認証・認可

### 4.6.1 Laravel Sanctum使用
```php
// config/sanctum.php 設定
'stateful' => explode(',', env('SANCTUM_STATEFUL_DOMAINS', sprintf(
    '%s%s',
    'localhost,localhost:3000,127.0.0.1,127.0.0.1:8000,::1',
    env('APP_URL') ? ','.parse_url(env('APP_URL'), PHP_URL_HOST) : ''
))),

// APIルートでの認証
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', fn(Request $request) => $request->user());
    Route::apiResource('posts', PostController::class);
});

// トークン発行
class AuthController extends Controller
{
    public function login(LoginRequest $request): JsonResponse
    {
        $credentials = $request->validated();
        
        if (!Auth::attempt($credentials)) {
            return response()->json([
                'message' => '認証情報が正しくありません。'
            ], 401);
        }
        
        $user = $request->user();
        $token = $user->createToken('API Token')->plainTextToken;
        
        return response()->json([
            'user' => new UserResource($user),
            'token' => $token,
        ]);
    }
}
```

## 4.7 テスト

### 4.7.1 PHPUnit使用
```php
// Feature Test
class PostTest extends TestCase
{
    use RefreshDatabase;
    
    public function test_user_can_create_post(): void
    {
        $user = User::factory()->create();
        
        $response = $this->actingAs($user)
                         ->postJson('/api/posts', [
                             'title' => 'Test Post',
                             'content' => 'This is test content.',
                             'status' => 'published',
                         ]);
        
        $response->assertStatus(201)
                 ->assertJsonStructure([
                     'id', 'title', 'slug', 'content', 'status'
                 ]);
        
        $this->assertDatabaseHas('posts', [
            'title' => 'Test Post',
            'user_id' => $user->id,
        ]);
    }
    
    public function test_post_requires_authentication(): void
    {
        $response = $this->postJson('/api/posts', [
            'title' => 'Test Post',
        ]);
        
        $response->assertUnauthorized();
    }
}

// Unit Test
class PostServiceTest extends TestCase
{
    public function test_create_post_with_valid_data(): void
    {
        $repository = $this->createMock(PostRepositoryInterface::class);
        $repository->expects($this->once())
                   ->method('save')
                   ->with($this->isInstanceOf(Post::class));
        
        $service = new PostService($repository);
        
        $data = [
            'title' => 'Test Post',
            'content' => 'Test content',
        ];
        
        $post = $service->createPost($data);
        
        $this->assertInstanceOf(Post::class, $post);
        $this->assertEquals('Test Post', $post->title);
    }
}
```

### 4.7.2 Factory・Seeder活用
```php
// Factory
class UserFactory extends Factory
{
    public function definition(): array
    {
        return [
            'name' => $this->faker->name(),
            'email' => $this->faker->unique()->safeEmail(),
            'email_verified_at' => now(),
            'password' => Hash::make('password'),
        ];
    }
    
    public function unverified(): static
    {
        return $this->state([
            'email_verified_at' => null,
        ]);
    }
    
    public function admin(): static
    {
        return $this->state([
            'role' => 'admin',
        ]);
    }
}

// Seeder
class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        User::factory()
            ->count(10)
            ->has(Post::factory()->count(5))
            ->create();
    }
}

// テストでの使用
$user = User::factory()
    ->has(Post::factory()->published()->count(3))
    ->admin()
    ->create();
```