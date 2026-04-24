# 14. パフォーマンス最適化

## 目次
- [14.1 Laravel パフォーマンス最適化](#141-laravel-パフォーマンス最適化)
- [14.2 フロントエンド最適化](#142-フロントエンド最適化)
- [14.3 データベース最適化](#143-データベース最適化)
- [14.4 キャッシュ戦略](#144-キャッシュ戦略)
- [14.5 APM・監視](#145-apm監視)

## 14.1 Laravel パフォーマンス最適化

### 14.1.1 設定の最適化

```php
// config/app.php
'debug' => env('APP_DEBUG', false),

// config/cache.php - Redis使用推奨
'default' => env('CACHE_DRIVER', 'redis'),

// config/session.php - Redis使用推奨
'driver' => env('SESSION_DRIVER', 'redis'),

// config/queue.php - Redis使用推奨
'default' => env('QUEUE_CONNECTION', 'redis'),
```

### 14.1.2 Eloquent最適化

```php
// N+1問題の回避
class PostController extends Controller
{
    public function index(): JsonResponse
    {
        $posts = Post::query()
            ->with(['user', 'tags', 'comments.user'])
            ->latest()
            ->paginate(20);

        return response()->json($posts);
    }
}

// バルクインサート
class BulkInsertService
{
    public function insertPosts(array $postData): void
    {
        // 一つずつ保存（悪い例）
        // foreach ($postData as $data) {
        //     Post::create($data);
        // }

        // バルクインサート（良い例）
        Post::insert($postData);
    }
}

// 選択的カラム取得
class UserRepository
{
    public function getForDropdown(): Collection
    {
        return User::query()
            ->select(['id', 'name'])
            ->orderBy('name')
            ->get();
    }
}

// チャンク処理
class DataMigrationCommand extends Command
{
    public function handle(): void
    {
        User::query()
            ->chunk(1000, function (Collection $users): void {
                foreach ($users as $user) {
                    // 処理
                }
            });
    }
}
```

### 14.1.3 ルートキャッシュ・設定キャッシュ

```bash
# 本番環境での最適化
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache

# Composerの最適化
composer install --no-dev --optimize-autoloader
```

### 14.1.4 キューの活用

```php
// 重い処理はキューで非同期実行
class SendEmailJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        private User $user,
        private string $template
    ) {}

    public function handle(MailService $mailService): void
    {
        $mailService->send($this->user, $this->template);
    }
}

// コントローラーからのディスパッチ
class UserController extends Controller
{
    public function store(CreateUserRequest $request): JsonResponse
    {
        $user = User::create($request->validated());

        // 非同期でウェルカムメール送信
        SendEmailJob::dispatch($user, 'welcome');

        return response()->json($user, 201);
    }
}
```

## 14.2 フロントエンド最適化

### 14.2.1 Vue.js パフォーマンス最適化

```vue
<!-- 良い例：v-show vs v-if -->
<template>
  <!-- 頻繁に切り替わる場合はv-show -->
  <div v-show="isVisible">Content</div>

  <!-- 条件が変わらない場合はv-if -->
  <div v-if="user.isAdmin">Admin Panel</div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'

// 計算プロパティのメモ化
const props = defineProps<{
  users: User[]
  searchTerm: string
}>()

const filteredUsers = computed(() => {
  if (!props.searchTerm) return props.users

  return props.users.filter(user =>
    user.name.toLowerCase().includes(props.searchTerm.toLowerCase())
  )
})

// 大量データの仮想スクロール
import { RecycleScroller } from 'vue-virtual-scroller'
</script>
```

### 14.2.2 コード分割・遅延読み込み

```typescript
// ルートレベルでのコード分割
const routes: RouteRecordRaw[] = [
  {
    path: '/users',
    component: () => import('@/views/Users/Index.vue')
  },
  {
    path: '/admin',
    component: () => import('@/views/Admin/Dashboard.vue')
  }
]

// コンポーネントの遅延読み込み
const LazyChart = defineAsyncComponent(() => import('@/components/Chart.vue'))
```

### 14.2.3 画像最適化

```vue
<template>
  <!-- 遅延読み込み -->
  <img
    :src="imageSrc"
    :alt="imageAlt"
    loading="lazy"
    class="w-full h-auto"
  />

  <!-- WebP対応 -->
  <picture>
    <source :srcset="webpSrc" type="image/webp">
    <img :src="fallbackSrc" :alt="imageAlt">
  </picture>
</template>
```

### 14.2.4 Bundle最適化

```javascript
// vite.config.js
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['vue', 'vue-router'],
          ui: ['@headlessui/vue', '@heroicons/vue']
        }
      }
    },
    chunkSizeWarningLimit: 1000
  }
})
```

## 14.3 データベース最適化

### 14.3.1 インデックス最適化

```php
// マイグレーションでのインデックス作成
class CreateOptimizedIndexesMigration extends Migration
{
    public function up(): void
    {
        Schema::table('posts', function (Blueprint $table): void {
            // 複合インデックス
            $table->index(['user_id', 'created_at']);
            $table->index(['status', 'published_at']);

            // 部分インデックス（MySQL 8.0+）
            $table->index(['title(10)']);
        });
    }
}

// モデルでのインデックスヒント
class Post extends Model
{
    public function scopeByUserAndDate(Builder $query, int $userId, string $date): Builder
    {
        return $query
            ->where('user_id', $userId)
            ->whereDate('created_at', $date)
            ->orderBy('created_at', 'desc');
    }
}
```

### 14.3.2 クエリ最適化

```php
class OptimizedRepository
{
    // EXPLAIN ANALYZEでクエリ分析
    public function analyzeQuery(): void
    {
        DB::enableQueryLog();

        $posts = Post::with(['user', 'tags'])
            ->where('status', 'published')
            ->latest()
            ->paginate(20);

        dump(DB::getQueryLog());
    }

    // サブクエリの最適化
    public function getUsersWithLatestPost(): Collection
    {
        return User::query()
            ->addSelect([
                'latest_post_title' => Post::query()
                    ->select('title')
                    ->whereColumn('user_id', 'users.id')
                    ->latest()
                    ->limit(1)
            ])
            ->get();
    }

    // ウィンドウ関数の活用
    public function getRankedPosts(): Collection
    {
        return DB::table('posts')
            ->select([
                '*',
                DB::raw('ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC) as rank')
            ])
            ->havingRaw('rank <= 5')
            ->get();
    }
}
```

## 14.4 キャッシュ戦略

### 14.4.1 アプリケーションレベルキャッシュ

```php
class CachedPostService
{
    public function __construct(
        private CacheManager $cache,
        private PostRepository $repository
    ) {}

    public function getPopularPosts(int $limit = 10): Collection
    {
        $key = "popular_posts:{$limit}";

        return $this->cache->remember(
            $key,
            now()->addHours(1),
            fn () => $this->repository->getPopular($limit)
        );
    }

    public function getUserPosts(int $userId): Collection
    {
        return $this->cache->tags(['users', "user:{$userId}"])
            ->remember(
                "user_posts:{$userId}",
                now()->addMinutes(30),
                fn () => $this->repository->getByUser($userId)
            );
    }

    // キャッシュの無効化
    public function invalidateUserCache(int $userId): void
    {
        $this->cache->tags(["user:{$userId}"])->flush();
    }
}

// モデルイベントでの自動キャッシュ無効化
class Post extends Model
{
    protected static function booted(): void
    {
        static::saved(function (Post $post): void {
            Cache::tags(['posts', "user:{$post->user_id}"])->flush();
        });
    }
}
```

### 14.4.2 HTTPキャッシュ

```php
// レスポンスキャッシュ
class ApiController extends Controller
{
    public function posts(): JsonResponse
    {
        $posts = Cache::remember('api.posts', 3600, function () {
            return Post::with(['user'])->latest()->get();
        });

        return response()
            ->json($posts)
            ->header('Cache-Control', 'public, max-age=3600');
    }
}

// ETags対応
class PostController extends Controller
{
    public function show(Post $post): JsonResponse
    {
        $etag = md5($post->updated_at);

        if (request()->header('If-None-Match') === $etag) {
            return response()->json(null, 304);
        }

        return response()
            ->json($post)
            ->header('ETag', $etag);
    }
}
```

### 14.4.3 Redis最適化

```php
// config/database.php
'redis' => [
    'default' => [
        'host' => env('REDIS_HOST', '127.0.0.1'),
        'port' => env('REDIS_PORT', 6379),
        'database' => 0,
        'options' => [
            'cluster' => env('REDIS_CLUSTER', 'redis'),
            'prefix' => env('REDIS_PREFIX', Str::slug(env('APP_NAME', 'laravel'), '_').'_database_'),
            // 接続プール
            'persistent' => true,
            // シリアライゼーション最適化
            'serializer' => 'igbinary',
            'compression' => 'lz4',
        ],
    ],
],
```

## 14.5 APM・監視

### 14.5.1 パフォーマンス監視

```php
// Laravelでの計測
class PerformanceMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $startTime = microtime(true);
        $startMemory = memory_get_usage();

        $response = $next($request);

        $duration = (microtime(true) - $startTime) * 1000;
        $memoryUsage = memory_get_usage() - $startMemory;

        Log::info('Request Performance', [
            'url' => $request->url(),
            'method' => $request->method(),
            'duration_ms' => round($duration, 2),
            'memory_mb' => round($memoryUsage / 1024 / 1024, 2),
            'queries' => DB::getQueryLog(),
        ]);

        return $response;
    }
}

// カスタムメトリクス
class MetricsService
{
    public function recordUserAction(string $action, array $tags = []): void
    {
        // InfluxDB、Prometheus等への送信
        $this->sendMetric('user.action', 1, array_merge($tags, [
            'action' => $action,
            'timestamp' => now()->timestamp,
        ]));
    }
}
```

### 14.5.2 アラート設定

```yaml
# docker-compose.yml - Prometheus設定例
version: '3.8'
services:
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=secret
```

### 14.5.3 パフォーマンステスト

```php
// Pest Performance Test
test('api response time', function (): void {
    $startTime = microtime(true);

    $response = $this->getJson('/api/posts');

    $duration = (microtime(true) - $startTime) * 1000;

    $response->assertStatus(200);
    expect($duration)->toBeLessThan(500); // 500ms以内
});

// Load Testing with Apache Bench
// ab -n 1000 -c 10 http://localhost/api/posts
```

### 14.5.4 継続的なパフォーマンス改善

```bash
# 定期的な最適化チェック
php artisan optimize
php artisan view:cache
php artisan config:cache
php artisan route:cache

# クエリ分析
php artisan telescope:clear
# アプリケーション使用後
php artisan telescope:publish
```

このパフォーマンス最適化ガイドにより、Laravel + Vue.jsアプリケーションの性能を最大化し、ユーザー体験を向上させることができます。