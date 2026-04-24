# 1. プロジェクト概要

## 1.1 プロジェクト名・目的

### プロジェクト名
- プロジェクト名: [プロジェクト名を記載]
- 開発コード: [開発コードを記載]

### 目的・概要
- [プロジェクトの目的と概要を記載]
- [対象ユーザー・利用シーンを記載]

## 1.2 技術スタック一覧

### バックエンド
- **PHP**: 8.2.27
- **Laravel Framework**: v11
- **Laravel Sanctum**: v4（API認証）
- **Laravel Prompts**: v0（CLI対話）
- **Laravel Pint**: v1（コード整形）
- **Laravel Sail**: v1（開発環境）
- **PHPUnit**: v11（テスト）

### フロントエンド
- **Vue.js**: v3（Composition API）
- **Tailwind CSS**: v3
- **Vite**: 最新版（ビルドツール）
- **Vitest**: 最新版（テスト）

### データベース
- **MariaDB**: 最新版

### 開発支援ツール
- **Laravel Boost**: 開発支援MCP サーバー
- **MailHog**: 開発環境でのメール確認

### インフラ・デプロイ
- **Docker**: コンテナ化
- **Nginx**: Webサーバー
- **PHP-FPM**: PHPプロセス管理
- **AWS ECS**: 本番環境（予定）
- **GitHub Actions**: CI/CD

## 1.3 開発環境構成

### ローカル開発環境
- Laravel Sailを使用したDocker環境
- Nginx + PHP-FPM + MariaDB + MailHog

### 開発フロー
1. ローカル開発（Laravel Sail）
2. GitHub へプッシュ
3. GitHub Actions による CI/CD
4. ステージング環境へのデプロイ
5. 本番環境へのデプロイ

### ディレクトリ構成
```
project-root/
├── app/                 # Laravel アプリケーション
├── bootstrap/           # Laravel 11 ブートストラップ
├── config/              # 設定ファイル
├── database/            # マイグレーション、シーダー
├── doc/                 # プロジェクトドキュメント
├── public/              # 公開ディレクトリ
├── resources/           # ビュー、CSS、JS
├── routes/              # ルート定義
├── storage/             # ログ、キャッシュ
├── tests/               # テストファイル
├── vendor/              # Composer依存関係
├── docker-compose.yml   # Docker設定
├── package.json         # npm設定
├── composer.json        # Composer設定
├── tailwind.config.js   # Tailwind設定
├── vite.config.js       # Vite設定
└── vitest.config.js     # Vitest設定
```