# 13. セキュリティ

## 13.1 CSRF対策

### 13.1.1 基本設定

```php
// config/session.php
'same_site' => 'lax', // CSRF攻撃を軽減
'secure' => env('SESSION_SECURE_COOKIE', true), // HTTPS環境でのみCookieを送信
'http_only' => true, // XSS攻撃からCookieを保護

// app/Http/Kernel.php (Laravel 11では bootstrap/app.php)
->withMiddleware(function (Middleware $middleware) {
    $middleware->web(append: [
        \App\Http\Middleware\VerifyCsrfToken::class,
    ]);
    
    // API用のCSRF除外設定
    $middleware->api(prepend: [
        \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
    ]);
})
```

### 13.1.2 Blade テンプレートでの実装

```php
<!-- resources/views/layouts/app.blade.php -->
<meta name="csrf-token" content="{{ csrf_token() }}">

<!-- フォーム内でのCSRFトークン -->
<form method="POST" action="{{ route('posts.store') }}">
    @csrf
    <input type="text" name="title" required>
    <button type="submit">投稿作成</button>
</form>

<!-- DELETE/PATCHメソッドの場合 -->
<form method="POST" action="{{ route('posts.destroy', $post) }}">
    @csrf
    @method('DELETE')
    <button type="submit">削除</button>
</form>
```

### 13.1.3 Vue.js での実装

```typescript
// resources/js/utils/csrf.ts
export function getCsrfToken(): string {
    const tokenMeta = document.querySelector('meta[name="csrf-token"]')
    if (!tokenMeta) {
        throw new Error('CSRF token not found')
    }
    return tokenMeta.getAttribute('content') || ''
}

// resources/js/api/client.ts
import axios from 'axios'
import { getCsrfToken } from '@/utils/csrf'

const apiClient = axios.create({
    baseURL: '/api',
    timeout: 10000,
    headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
    },
})

// リクエストインターセプターでCSRFトークンを自動付与
apiClient.interceptors.request.use(config => {
    const token = getCsrfToken()
    if (token) {
        config.headers['X-CSRF-TOKEN'] = token
    }
    return config
})

export default apiClient

// 使用例
export const postApi = {
    create: (data: CreatePostData) => 
        apiClient.post('/posts', data),
    update: (id: number, data: UpdatePostData) => 
        apiClient.put(`/posts/${id}`, data),
    delete: (id: number) => 
        apiClient.delete(`/posts/${id}`),
}
```

## 13.2 XSS対策

### 13.2.1 出力エスケープ

```php
<!-- Blade テンプレートでの自動エスケープ -->
<h1>{{ $post->title }}</h1> <!-- 自動エスケープされる -->
<p>{{ $post->content }}</p>

<!-- HTMLを意図的に出力する場合（信頼できるデータのみ） -->
<div>{!! $post->html_content !!}</div> <!-- 要注意：XSSリスクあり -->

<!-- 条件付きエスケープ -->
<div>{{ $post->is_html ? strip_tags($post->content) : $post->content }}</div>

<!-- HTMLPurifierを使用した安全なHTML出力 -->
<div>{!! app('html-purifier')->clean($post->content) !!}</div>
```

```php
// app/Helpers/SecurityHelper.php
class SecurityHelper
{
    /**
     * XSS攻撃を防ぐためのHTMLクリーニング
     */
    public static function cleanHtml(string $html): string
    {
        // HTMLPurifierを使用
        $config = \HTMLPurifier_Config::createDefault();
        $config->set('HTML.Allowed', 'p,br,strong,em,ul,ol,li,a[href],img[src|alt]');
        $config->set('HTML.ForbiddenElements', 'script,iframe,object,embed');
        $config->set('HTML.ForbiddenAttributes', 'onclick,onload,onerror,style');
        
        $purifier = new \HTMLPurifier($config);
        return $purifier->purify($html);
    }
    
    /**
     * JavaScriptで使用する文字列のエスケープ
     */
    public static function escapeJs(string $string): string
    {
        return json_encode($string, JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT);
    }
    
    /**
     * URL パラメータのサニタイズ
     */
    public static function sanitizeUrl(string $url): string
    {
        // 危険なプロトコルをチェック
        $dangerousProtocols = ['javascript:', 'data:', 'vbscript:', 'file:'];
        
        foreach ($dangerousProtocols as $protocol) {
            if (str_starts_with(strtolower($url), $protocol)) {
                return '#';
            }
        }
        
        return filter_var($url, FILTER_SANITIZE_URL) ?: '#';
    }
}
```

### 13.2.2 フロントエンドでのXSS対策

```typescript
// resources/js/utils/security.ts

/**
 * HTMLエスケープ関数
 */
export function escapeHtml(text: string): string {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
}

/**
 * XSS攻撃を防ぐDOMSanitizerラッパー
 */
export function sanitizeHtml(html: string): string {
    if ('trustedTypes' in window && window.trustedTypes) {
        const policy = window.trustedTypes.createPolicy('sanitize-html', {
            createHTML: (input) => input
        })
        return policy.createHTML(html).toString()
    }
    
    // fallback: DOMPurifyを使用
    return DOMPurify.sanitize(html)
}

// Vue.js コンポーネントでの使用例
<template>
  <div>
    <!-- 自動エスケープ -->
    <h1>{{ post.title }}</h1>
    
    <!-- サニタイズされたHTML -->
    <div v-html="sanitizedContent"></div>
    
    <!-- URLのサニタイズ -->
    <a :href="sanitizeUrl(post.external_link)" target="_blank">
      外部リンク
    </a>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { sanitizeHtml, sanitizeUrl } from '@/utils/security'

interface Props {
  post: {
    title: string
    content: string
    external_link: string
  }
}

const props = defineProps<Props>()

const sanitizedContent = computed(() => {
  return sanitizeHtml(props.post.content)
})
</script>
```

## 13.3 SQLインジェクション対策

### 13.3.1 Eloquent ORM の適切な使用

```php
// ✅ Good: パラメータ化クエリ（自動的にエスケープ）
class PostService
{
    public function findByTitle(string $title): Collection
    {
        return Post::where('title', 'LIKE', "%{$title}%")->get();
    }
    
    public function findByCategories(array $categoryIds): Collection
    {
        return Post::whereIn('category_id', $categoryIds)->get();
    }
    
    public function complexSearch(array $filters): Collection
    {
        $query = Post::query();
        
        if (!empty($filters['title'])) {
            $query->where('title', 'LIKE', "%{$filters['title']}%");
        }
        
        if (!empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }
        
        if (!empty($filters['date_from'])) {
            $query->where('created_at', '>=', $filters['date_from']);
        }
        
        return $query->get();
    }
}

// ❌ Bad: 生のSQL文字列結合（SQLインジェクション脆弱性）
class BadPostService
{
    public function findByTitle(string $title): Collection
    {
        // 危険: SQLインジェクション脆弱性
        return DB::select("SELECT * FROM posts WHERE title LIKE '%{$title}%'");
    }
}
```

### 13.3.2 生SQLを使用する場合の対策

```php
// 生SQLを使用する場合は必ずパラメータバインディングを使用
class PostRepository
{
    public function getPostsWithComplexJoin(array $filters): Collection
    {
        $sql = "
            SELECT p.*, u.name as author_name, 
                   COUNT(c.id) as comment_count
            FROM posts p
            LEFT JOIN users u ON p.user_id = u.id
            LEFT JOIN comments c ON p.id = c.post_id
            WHERE p.status = ? 
        ";
        
        $params = ['published'];
        
        if (!empty($filters['category'])) {
            $sql .= " AND p.category_id = ?";
            $params[] = $filters['category'];
        }
        
        if (!empty($filters['author'])) {
            $sql .= " AND u.name LIKE ?";
            $params[] = "%{$filters['author']}%";
        }
        
        $sql .= " GROUP BY p.id ORDER BY p.created_at DESC";
        
        return collect(DB::select($sql, $params));
    }
    
    public function updatePostCounts(): void
    {
        // 名前付きバインディングも使用可能
        DB::statement("
            UPDATE posts p
            SET comment_count = (
                SELECT COUNT(*) 
                FROM comments c 
                WHERE c.post_id = p.id
            )
            WHERE p.status = :status
        ", ['status' => 'published']);
    }
}
```

### 13.3.3 バリデーションによる入力値検証

```php
// app/Http/Requests/PostSearchRequest.php
class PostSearchRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'title' => 'nullable|string|max:255',
            'category_id' => 'nullable|integer|exists:categories,id',
            'status' => 'nullable|string|in:draft,published,archived',
            'author_id' => 'nullable|integer|exists:users,id',
            'date_from' => 'nullable|date',
            'date_to' => 'nullable|date|after_or_equal:date_from',
            'sort_by' => 'nullable|string|in:title,created_at,updated_at',
            'sort_direction' => 'nullable|string|in:asc,desc',
            'per_page' => 'nullable|integer|min:1|max:100',
        ];
    }
    
    public function messages(): array
    {
        return [
            'category_id.exists' => '指定されたカテゴリは存在しません。',
            'author_id.exists' => '指定された著者は存在しません。',
            'status.in' => 'ステータスは draft, published, archived のいずれかを指定してください。',
        ];
    }
    
    protected function prepareForValidation(): void
    {
        // 入力値の前処理・サニタイズ
        $this->merge([
            'title' => $this->sanitizeTitle($this->title),
            'per_page' => $this->per_page ?: 20,
            'sort_direction' => strtolower($this->sort_direction ?: 'desc'),
        ]);
    }
    
    private function sanitizeTitle(?string $title): ?string
    {
        if (!$title) return null;
        
        // HTML タグを除去
        $title = strip_tags($title);
        
        // 特殊文字をエスケープ
        $title = htmlspecialchars($title, ENT_QUOTES, 'UTF-8');
        
        // 長すぎる場合は切り詰め
        return Str::limit($title, 255);
    }
}
```

## 13.4 認証・認可

### 13.4.1 Laravel Sanctum による API 認証

```php
// config/sanctum.php
'stateful' => explode(',', env('SANCTUM_STATEFUL_DOMAINS', sprintf(
    '%s%s',
    'localhost,localhost:3000,127.0.0.1,127.0.0.1:8000,::1',
    Sanctum::currentApplicationUrlWithPort()
))),

'expiration' => env('SANCTUM_TOKEN_EXPIRATION', 60 * 24), // 24時間

'middleware' => [
    'verify_csrf_token' => App\Http\Middleware\VerifyCsrfToken::class,
    'encrypt_cookies' => App\Http\Middleware\EncryptCookies::class,
],

// app/Http/Controllers/Auth/AuthController.php
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
        
        // アカウント状態チェック
        if (!$user->isActive()) {
            Auth::logout();
            return response()->json([
                'message' => 'アカウントが無効化されています。'
            ], 403);
        }
        
        // メール認証チェック
        if (!$user->hasVerifiedEmail()) {
            return response()->json([
                'message' => 'メールアドレスの認証が必要です。',
                'requires_verification' => true
            ], 403);
        }
        
        // トークン生成
        $token = $user->createToken('API Token', [
            'posts:read',
            'posts:write',
            'profile:read',
            'profile:write'
        ]);
        
        // ログイン試行履歴を記録
        $this->recordLoginAttempt($user, $request, true);
        
        return response()->json([
            'user' => new UserResource($user),
            'token' => $token->plainTextToken,
            'expires_at' => $token->accessToken->expires_at,
        ]);
    }
    
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();
        
        return response()->json([
            'message' => 'ログアウトしました。'
        ]);
    }
    
    public function refresh(Request $request): JsonResponse
    {
        $user = $request->user();
        
        // 現在のトークンを削除
        $user->currentAccessToken()->delete();
        
        // 新しいトークンを生成
        $token = $user->createToken('API Token');
        
        return response()->json([
            'token' => $token->plainTextToken,
            'expires_at' => $token->accessToken->expires_at,
        ]);
    }
    
    private function recordLoginAttempt(User $user, Request $request, bool $successful): void
    {
        LoginAttempt::create([
            'user_id' => $user->id,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
            'successful' => $successful,
            'attempted_at' => now(),
        ]);
    }
}
```

### 13.4.2 認可（Authorization）

```php
// app/Policies/PostPolicy.php
class PostPolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }
    
    public function view(?User $user, Post $post): bool
    {
        // 公開済みの投稿は誰でも閲覧可能
        if ($post->isPublished()) {
            return true;
        }
        
        // 下書きは作成者のみ閲覧可能
        return $user && $user->id === $post->user_id;
    }
    
    public function create(User $user): bool
    {
        return $user->isVerified() && $user->isActive();
    }
    
    public function update(User $user, Post $post): bool
    {
        // 管理者または投稿作成者
        return $user->isAdmin() || $user->id === $post->user_id;
    }
    
    public function delete(User $user, Post $post): bool
    {
        return $user->isAdmin() || $user->id === $post->user_id;
    }
    
    public function publish(User $user, Post $post): bool
    {
        // 編集者権限以上が必要
        return $user->hasRole(['admin', 'editor']) || 
               ($user->id === $post->user_id && $user->canPublishPosts());
    }
}

// app/Http/Controllers/PostController.php
class PostController extends Controller
{
    public function show(Post $post): JsonResponse
    {
        $this->authorize('view', $post);
        
        return response()->json(new PostResource($post));
    }
    
    public function store(StorePostRequest $request): JsonResponse
    {
        $this->authorize('create', Post::class);
        
        $post = Post::create([
            ...$request->validated(),
            'user_id' => auth()->id(),
        ]);
        
        return response()->json(new PostResource($post), 201);
    }
    
    public function update(UpdatePostRequest $request, Post $post): JsonResponse
    {
        $this->authorize('update', $post);
        
        $post->update($request->validated());
        
        return response()->json(new PostResource($post));
    }
    
    public function publish(Post $post): JsonResponse
    {
        $this->authorize('publish', $post);
        
        $post->publish();
        
        return response()->json(new PostResource($post));
    }
}
```

### 13.4.3 セキュリティヘッダー

```php
// app/Http/Middleware/SecurityHeaders.php
class SecurityHeaders
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);
        
        // XSS Protection
        $response->headers->set('X-Content-Type-Options', 'nosniff');
        $response->headers->set('X-Frame-Options', 'DENY');
        $response->headers->set('X-XSS-Protection', '1; mode=block');
        
        // HSTS (HTTPS環境のみ)
        if ($request->isSecure()) {
            $response->headers->set(
                'Strict-Transport-Security',
                'max-age=31536000; includeSubDomains'
            );
        }
        
        // CSP (Content Security Policy)
        $csp = [
            "default-src 'self'",
            "script-src 'self' 'unsafe-inline' 'unsafe-eval'", // 開発時のみ unsafe-*
            "style-src 'self' 'unsafe-inline'",
            "img-src 'self' data: https:",
            "font-src 'self'",
            "connect-src 'self'",
            "media-src 'none'",
            "object-src 'none'",
            "child-src 'none'",
            "frame-ancestors 'none'",
            "form-action 'self'",
            "base-uri 'self'",
        ];
        
        $response->headers->set(
            'Content-Security-Policy',
            implode('; ', $csp)
        );
        
        // Referrer Policy
        $response->headers->set(
            'Referrer-Policy',
            'strict-origin-when-cross-origin'
        );
        
        // Feature Policy / Permissions Policy
        $permissions = [
            'camera=()' ,
            'microphone=()',
            'geolocation=()',
            'payment=()',
        ];
        
        $response->headers->set(
            'Permissions-Policy',
            implode(', ', $permissions)
        );
        
        return $response;
    }
}
```