# 3. アーキテクチャ設計原則

## 3.1 クリーンアーキテクチャ

### 3.1.1 凝集度の原則
- **高凝集度を目指す**：関連する機能は同じモジュールにまとめる
- **単一責任の原則**：各クラス・モジュールは一つの責任のみを持つ
- **共通の理由で変更されるものをまとめる**

### 3.1.2 依存の向きと安定度
- **安定な方向への依存**：不安定なモジュールは安定なモジュールに依存する
- **依存逆転の原則**：抽象に依存し、具体に依存しない
- **インターフェース分離の原則**

### 3.1.3 ドメイン駆動設計

Laravelでは、以下の4層に責務を分離してアーキテクチャを構成する。

#### Controller層（リクエストとレスポンスの入り口）
- **役割**：HTTPリクエストの受付とレスポンスの返却
- **責務**：
  - リクエストの受け取り
  - バリデーション（FormRequest使用）
  - Serviceの呼び出し
  - レスポンスの整形

```php
class UserController extends Controller
{
    public function __construct(
        private readonly UserService $userService
    ) {}

    public function store(UserRequest $request): JsonResponse
    {
        $user = $this->userService->createUser($request->validated());

        return response()->json($user, 201);
    }
}
```

#### Service層（ビジネスロジック）
- **役割**：アプリケーションのビジネスロジック
- **責務**：
  - 複雑なビジネスルールの実装
  - 複数Repositoryの調整
  - トランザクション管理
  - 外部サービスとの連携

```php
class UserService
{
    public function __construct(
        private readonly UserRepositoryInterface $userRepository,
        private readonly EmailService $emailService
    ) {}

    public function createUser(array $data): User
    {
        // ビジネスロジック
        $data['password'] = Hash::make($data['password']);

        // データ保存
        $user = $this->userRepository->create($data);

        // 外部連携
        $this->emailService->sendWelcomeEmail($user);

        return $user;
    }
}
```

#### Repository層（データアクセスの抽象化）
- **役割**：データ永続化の抽象化
- **責務**：
  - データの保存・取得・更新・削除
  - クエリロジックのカプセル化
  - Modelの操作

**インターフェース定義（抽象）：**
```php
interface UserRepositoryInterface
{
    public function create(array $data): User;
    public function findByEmail(string $email): ?User;
    public function findById(int $id): ?User;
    public function update(User $user, array $data): User;
    public function delete(User $user): bool;
}
```

**実装（具象）：**
```php
class UserRepository implements UserRepositoryInterface
{
    public function create(array $data): User
    {
        return User::create($data);
    }

    public function findByEmail(string $email): ?User
    {
        return User::where('email', $email)->first();
    }

    public function findById(int $id): ?User
    {
        return User::find($id);
    }

    public function update(User $user, array $data): User
    {
        $user->update($data);
        return $user->fresh();
    }

    public function delete(User $user): bool
    {
        return $user->delete();
    }
}
```

#### Model層（テーブルとオブジェクトのマッピング）
- **役割**：データベーステーブルとのマッピング
- **責務**：
  - テーブル構造の定義
  - リレーションの定義
  - アクセサ・ミューテータ
  - スコープ定義

```php
class User extends Model
{
    protected $fillable = [
        'name',
        'email',
        'password',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    // リレーション定義
    public function posts(): HasMany
    {
        return $this->hasMany(Post::class);
    }

    public function profile(): HasOne
    {
        return $this->hasOne(Profile::class);
    }

    // スコープ定義
    public function scopeActive(Builder $query): void
    {
        $query->where('is_active', true);
    }
}
```

#### レイヤー間の依存関係

```
Controller層
    ↓（依存）
Service層
    ↓（依存）
Repository層（Interface）
    ↓（実装）
Repository層（Implementation）
    ↓（使用）
Model層
```

- **依存の向き**：上位レイヤーから下位レイヤーへ
- **抽象への依存**：ServiceはRepositoryInterfaceに依存
- **具象の注入**：DIコンテナで具象クラスを注入

#### DI設定例

```php
// app/Providers/AppServiceProvider.php
class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Repository Pattern DI Binding
        $this->app->bind(
            UserRepositoryInterface::class,
            UserRepository::class
        );
    }
}
```

#### 従来のアーキテクチャ概念との対応

##### ドメインモデル
- **Entity**：Modelクラスに対応
- **Value Object**：不変の値オブジェクト（必要に応じて作成）
- **Domain Service**：Service層に対応
- **Repository Interface**：Repository層のInterfaceに対応

##### ユースケース
- **Application Service**：Service層に対応
- **Command/Query**：CQRSパターンの実装（必要に応じて）
- **DTO (Data Transfer Object)**：FormRequestやResourceに対応

##### インターフェースアダプター
- **Controller**：Controller層に対応
- **Presenter**：API ResourceやViewに対応
- **Gateway**：外部APIとの結合（Service層またはRepository層）

##### インフラストラクチャ
- **Repository Implementation**：Repository層の実装クラスに対応
- **External Service**：外部サービス連携（Service層）
- **Framework Integration**：Laravel固有機能の結合

## 3.2 パッケージ原則

### 3.2.1 再利用・リリース等価の原則
- 再利用の粒度はリリースの粒度と等価
- 一緒にリリースされるものを一緒に再利用
- バージョン管理の単位と再利用の単位を合わせる

### 3.2.2 全再利用の原則
- パッケージのすべてのクラスを再利用するか、まったくしないか
- 部分的な再利用を避ける
- 不要な依存関係を作らない

### 3.2.3 閉鎖性共通の原則
- 同じ理由で変更されるクラスを同じパッケージに
- 変更に対してパッケージを閉じる
- 影響範囲を限定し、修正を局所化する

### 3.2.4 非循環依存関係の原則
- パッケージ依存グラフは非循環であるべき
- 循環依存があるとビルド・テストが困難
- インターフェースや抽象クラスで循環を断ち切る

### 3.2.5 安定依存の原則
- 安定度の低いパッケージは安定度の高いパッケージに依存
- 変更頻度の高いモジュールは変更頻度の低いモジュールに依存
- コンクリートではなくインターフェースに依存

## 3.3 オブジェクト指向設計

### 3.3.1 カプセル化
- **データ隠蔽**：内部データを直接操作させない
- **アクセサメソッド**：適切なgetter/setterを提供
- **ビジネスロジックの隠蔽**：実装詳細を隠し、インターフェースを提供

### 3.3.2 多態性
- **インターフェースの活用**：共通の振る舞いを定義
- **抽象クラス**：共通の実装を提供
- **メソッドオーバーライド**：サブクラスでの特化

### 3.3.3 継承/汎化
- **is-a関係**：真の汎化関係のみ継承を使用
- **継承よりコンポジション**：has-a関係ではコンポジションを選択
- **継承階層の制限**：深すぎる継承を避ける

### 3.3.4 SOLID原則

#### S: 単一責任の原則 (Single Responsibility Principle)
- クラスが変更される理由は一つであるべき
- 一つのクラスに一つの責任

#### O: 開放閉鎖の原則 (Open-Closed Principle)
- 拡張に対して開放、修正に対して閉鎖
- インターフェースや抽象クラスで拡張性を確保

#### L: リスコフ置換の原則 (Liskov Substitution Principle)
- サブクラスはスーパークラスと置換可能であるべき
- サブクラスはスーパークラスのコントラクトを破ってはいけない

#### I: インターフェース分離の原則 (Interface Segregation Principle)
- クライアントは使用しないメソッドへの依存を強制されてはいけない
- 小さく特化されたインターフェースを作る

#### D: 依存逆転の原則 (Dependency Inversion Principle)
- 上位モジュールは下位モジュールに依存してはいけない
- 両方とも抽象に依存すべき
- 抽象は詳細に依存してはいけない

## 3.4 デザインパターン

### 3.4.1 生成に関するパターン

#### Factory Pattern
- オブジェクト生成の抽象化
- 具体クラスを明示しないオブジェクト生成
- LaravelでのModel Factoryの活用

#### Builder Pattern
- 複雑なオブジェクトの段階的構築
- メソッドチェーンによる流れるようなインターフェース
- Query BuilderやValidation Rule Builder

#### Singleton Pattern
- インスタンスが一つだけ必要なクラス
- LaravelのDIコンテナでのシングルトン管理
- グローバル状態の管理

### 3.4.2 構造に関するパターン

#### Adapter Pattern
- 互換性のないインターフェースを接続
- 外部APIやライブラリの統合
- 既存システムとの連携

#### Decorator Pattern
- 既存オブジェクトに動的に機能を追加
- LaravelのMiddlewareの仕組み
- キャッシュ、ログ出力などの横断関心事

#### Facade Pattern
- 複雑なサブシステムへのシンプルなインターフェース
- Laravel Facadeの活用
- APIの簡略化と統一

### 3.4.3 振る舞いに関するパターン

#### Strategy Pattern
- アルゴリズムの動的変更
- 条件分岐の整理と拡張性の確保
- 決済方法、通知方法などの実装

#### Observer Pattern
- オブジェクト間の一対多依存関係
- Laravel Event/Listenerの活用
- Model Observerでのモデルライフサイクル監視

#### Command Pattern
- リクエストのカプセル化
- アンドゥ・リドゥ機能
- ジョブキューでの非同期処理

### 3.4.4 Laravel固有のパターン

#### Repository Pattern
- データアクセスの抽象化
- テスト可能性の向上
- データソースの切り替え対応

#### Service Pattern
- ビジネスロジックのカプセル化
- Controllerのスリム化
- 再利用性の向上

#### Provider Pattern
- サービスのDIコンテナ登録
- アプリケーションのブートストラップ
- 設定やサービスの初期化