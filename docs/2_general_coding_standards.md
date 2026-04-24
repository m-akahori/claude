# 2. 全般的なコーディング規約

## 2.1 命名規則

### 2.1.1 基本原則
- **英語を使用**：変数、関数、クラス名は英語で命名する
- **意味のある名前**：略語を避け、意図が明確に伝わる名前を使用する
- **一貫性を保つ**：同じ概念には同じ命名パターンを使用する

### 2.1.2 言語別命名規則

#### PHP
- **クラス名**: PascalCase（例：`UserService`, `PaymentController`）
- **メソッド名**: camelCase（例：`getUserById`, `processPayment`）
- **変数名**: camelCase（例：`$userName`, `$paymentAmount`）
- **定数名**: UPPER_SNAKE_CASE（例：`MAX_RETRY_COUNT`, `DEFAULT_TIMEOUT`）
- **ファイル名**: PascalCase（例：`UserService.php`）

#### JavaScript/Vue.js
- **変数名**: camelCase（例：`userName`, `isLoading`）
- **関数名**: camelCase（例：`fetchUserData`, `handleSubmit`）
- **コンポーネント名**: PascalCase（例：`UserProfile.vue`, `PaymentForm.vue`）
- **定数名**: UPPER_SNAKE_CASE（例：`API_ENDPOINT`, `MAX_ITEMS`）

#### CSS/Tailwind
- **クラス名**: kebab-case（例：`user-profile`, `payment-form`）
- **カスタムプロパティ**: kebab-case（例：`--primary-color`, `--font-size-large`）

#### データベース
- **テーブル名**: snake_case、複数形（例：`users`, `payment_transactions`）
- **カラム名**: snake_case（例：`user_name`, `created_at`）
- **インデックス名**: `idx_table_column`（例：`idx_users_email`）

### 2.1.3 特別な命名規則
- **Boolean値**: `is`, `has`, `can`, `should`で始める（例：`isActive`, `hasPermission`）
- **配列・コレクション**: 複数形を使用（例：`users`, `items`）
- **イベントハンドラー**: `handle`, `on`で始める（例：`handleClick`, `onSubmit`）

## 2.2 コメント・ドキュメント

### 2.2.1 基本方針
- **コードは自己説明的に**：コメントに頼らず、コード自体が読みやすくなるよう心がける
- **なぜを説明**：「何を」ではなく「なぜ」を説明する
- **PHPDoc形式**：PHP関数・メソッドにはPHPDocブロックを使用

### 2.2.2 PHPDocブロック
```php
/**
 * ユーザー情報を取得する
 *
 * @param int $userId ユーザーID
 * @param array $options 取得オプション
 * @return User|null ユーザーオブジェクト、見つからない場合はnull
 * @throws UserNotFoundException ユーザーが見つからない場合
 */
public function getUserById(int $userId, array $options = []): ?User
{
    // 実装
}
```

### 2.2.3 JSDoc形式（Vue.js/JavaScript）
```javascript
/**
 * ユーザーデータを取得する
 * @param {number} userId - ユーザーID
 * @param {Object} options - 取得オプション
 * @returns {Promise<User|null>} ユーザーオブジェクトまたはnull
 */
const fetchUser = async (userId, options = {}) => {
    // 実装
}
```

### 2.2.4 避けるべきコメント
- 明らかな内容の説明
- 古い情報や間違った情報
- コメントアウトされたコード（バージョン管理があるため不要）

## 2.3 ファイル構成・ディレクトリ構造

### 2.3.1 Laravel 11 構造
```
app/
├── Console/
│   └── Commands/         # Artisanコマンド（自動登録）
├── Exceptions/           # カスタム例外クラス
├── Http/
│   ├── Controllers/      # コントローラー
│   ├── Middleware/       # カスタムミドルウェア（少数）
│   └── Requests/         # Form Requestクラス
├── Models/               # Eloquentモデル
├── Providers/            # サービスプロバイダー
└── Services/             # ビジネスロジック

bootstrap/
├── app.php              # アプリケーション設定（Laravel 11の中心）
└── providers.php        # プロバイダー登録

resources/
├── css/                 # Tailwind CSS
├── js/                  # Vue.js コンポーネント
│   ├── components/       # 再利用可能コンポーネント
│   ├── pages/           # ページ固有コンポーネント
│   └── stores/          # 状態管理（Pinia等）
└── views/               # Blade テンプレート
```

### 2.3.2 コンポーネント構成（Vue.js）
```
resources/js/
├── components/
│   ├── ui/              # 基本UIコンポーネント
│   │   ├── Button.vue
│   │   ├── Input.vue
│   │   └── Modal.vue
│   ├── forms/           # フォーム関連
│   │   ├── UserForm.vue
│   │   └── PaymentForm.vue
│   └── layouts/         # レイアウト
│       ├── AppLayout.vue
│       └── AuthLayout.vue
├── pages/               # ページコンポーネント
│   ├── users/
│   │   ├── Index.vue
│   │   ├── Show.vue
│   │   └── Edit.vue
│   └── auth/
│       ├── Login.vue
│       └── Register.vue
├── stores/              # 状態管理
├── utils/               # ユーティリティ関数
└── types/               # TypeScript型定義（使用時）
```

### 2.3.3 ファイル命名規則
- **単一責任の原則**：1ファイル1クラス/1コンポーネント
- **機能別ディレクトリ**：関連する機能をまとめて配置
- **深すぎる階層を避ける**：3階層以下を目安とする

## 2.4 Git運用ルール

### 2.4.1 ブランチ戦略
- **main/master**: 本番環境用
- **develop**: 開発統合用
- **feature/[issue-number]-[description]**: 機能開発用
- **hotfix/[description]**: 緊急修正用
- **release/[version]**: リリース準備用

### 2.4.2 コミットメッセージ規約
```
[種別] 概要（50文字以内）

詳細説明（必要に応じて）
- 変更点1
- 変更点2

関連課題: #123
```

#### コミット種別
- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメント更新
- `style`: コード整形（機能に影響なし）
- `refactor`: リファクタリング
- `test`: テスト追加・修正
- `chore`: ビルドプロセスやツール変更

### 2.4.3 プルリクエスト規約
- **テンプレートを使用**
- **関連課題をリンク**
- **スクリーンショット添付**（UI変更時）
- **テストが通ることを確認**
- **コードレビューを必須とする**

### 2.4.4 禁止事項
- 直接main/masterブランチへのプッシュ
- 機密情報のコミット
- 巨大なバイナリファイルのコミット
- 意味のないコミットメッセージ