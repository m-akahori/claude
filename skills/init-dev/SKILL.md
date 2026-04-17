---
name: init-dev
description: 新規クローンしたLaravelプロジェクトをローカル環境で開発できるように初期化する
disable-model-invocation: true
allowed-tools: Bash(cp *) Bash(sed *) Bash(lsof *) Bash(sudo *) Bash(composer *) Bash(npm *) Bash(docker *) Bash(php *) Bash(open *)
---

GitリポジトリからクローンしたLaravelプロジェクトをローカル環境で開発開始できる状態にします。

ポートのデフォルト値は [port-defaults.md](port-defaults.md) を参照。
トラブルシューティングは [troubleshooting.md](troubleshooting.md) を参照。

# ゴール

HTTPSで独自ドメインでブラウザに接続でき、新しいプロジェクトがローカル環境で開発開始できるようになること

# 手順

## 1. プロジェクト固有設定の入力

以下の項目についてユーザーに入力を求めます：

1. **APP_NAME**: プロジェクト名（例: regrit, idol など）
2. **APP_TLD**: トップレベルドメイン（例: co.jp, com など）

## 2. .envファイルの作成

.env.localをベースに.envファイルを作成します。

```bash
cp .env.local .env
```

### 2-1. APP_NAMEとAPP_TLDの設定

ユーザー入力値を.envと.env.localの両方に反映します。

```bash
sed -i '' "s/^APP_NAME=.*/APP_NAME={ユーザー入力のAPP_NAME}/" .env
sed -i '' "s/^APP_TLD=.*/APP_TLD={ユーザー入力のAPP_TLD}/" .env

sed -i '' "s/^APP_NAME=.*/APP_NAME={ユーザー入力のAPP_NAME}/" .env.local
sed -i '' "s/^APP_TLD=.*/APP_TLD={ユーザー入力のAPP_TLD}/" .env.local
```

### 2-2. ポート番号の自動調整

他のプロジェクトとポート競合を避けるため、port-defaults.md のデフォルト値から+1した値を提案します。

各ポートが使用されているか確認します：

```bash
lsof -i :4432
lsof -i :33017
lsof -i :1252
lsof -i :8252
lsof -i :51732
```

問題がなければ、.envと.env.localに反映します：

```bash
sed -i '' "s/^APP_PORT=.*/APP_PORT=4432/" .env
sed -i '' "s/^DB_LOCAL_PORT=.*/DB_LOCAL_PORT=33017/" .env
sed -i '' "s/^MAILHOG_LOCAL_PORT=.*/MAILHOG_LOCAL_PORT=1252/" .env
sed -i '' "s/^MAILHOG_WEB_PORT=.*/MAILHOG_WEB_PORT=8252/" .env
sed -i '' "s/^VITE_PORT=.*/VITE_PORT=51732/" .env

sed -i '' "s/^APP_PORT=.*/APP_PORT=4432/" .env.local
sed -i '' "s/^DB_LOCAL_PORT=.*/DB_LOCAL_PORT=33017/" .env.local
sed -i '' "s/^MAILHOG_LOCAL_PORT=.*/MAILHOG_LOCAL_PORT=1252/" .env.local
sed -i '' "s/^MAILHOG_WEB_PORT=.*/MAILHOG_WEB_PORT=8252/" .env.local
sed -i '' "s/^VITE_PORT=.*/VITE_PORT=51732/" .env.local
```

## 3. hostsファイルにドメインを追加

```bash
sudo nano /etc/hosts
```

以下の行を追加：

```
127.0.0.1 {APP_NAME}-local.{APP_TLD}
```

例：APP_NAME=idol、APP_TLD=co.jpの場合
```
127.0.0.1 idol-local.co.jp
```

## 4. Composer依存関係のインストール

Dockerコンテナ起動前にホストマシンで実行します。

```bash
composer install
```

## 5. Node.js依存関係のインストール

```bash
npm install
```

## 6. Dockerコンテナの起動

```bash
docker compose up -d
docker compose ps
```

## 7. アプリケーションキーの生成

```bash
docker compose exec php-fpm php artisan key:generate
```

## 8. データベースマイグレーション

```bash
docker compose exec php-fpm php artisan migrate
```

## 9. データベースシーダーの実行

```bash
docker compose exec php-fpm php artisan db:seed
```

シーダーが存在しない場合はスキップしてください。

## 10. Vite用SSL証明書の生成

**重要**: `update-dev-certs.sh` は環境変数 `APP_NAME` と `APP_TLD` を使用するため、実行時に設定が必要です。

```bash
APP_NAME={ユーザー入力のAPP_NAME} APP_TLD={ユーザー入力のAPP_TLD} ./update-dev-certs.sh
```

例：
```bash
APP_NAME=idol-ichiban APP_TLD=com ./update-dev-certs.sh
```

正常に完了すると以下が表示されます：

```
✅ Certificates updated successfully!
📁 Certificate: ./dev-certs/{APP_NAME}-local.{APP_TLD}.pem
🔑 Private key: ./dev-certs/{APP_NAME}-local.{APP_TLD}-key.pem
```

## 11. Vite開発サーバーの起動

```bash
npm run dev
```

ViteサーバーがHTTPSで起動したことを確認してください：

```
➜  Local:   https://localhost:{VITE_PORT}/
➜  Local:   https://{APP_NAME}-local.{APP_TLD}:{VITE_PORT}/
```

**注意**: `http://` で起動している場合は手順10に戻って証明書を生成してください。

## 12. ブラウザでアプリケーションを開く

### ステップ1: アプリケーションURLを開く

```bash
open "https://{APP_NAME}-local.{APP_TLD}:{APP_PORT}"
```

### ステップ2: Vite開発サーバーURLを開く

```bash
open "https://localhost:{VITE_PORT}"
```

### ステップ3: 証明書を許可

1. Vite開発サーバーのタブで「詳細設定」→「安全でないサイトに進む」を選択
2. アプリケーションのタブで「詳細設定」→「安全でないサイトに進む」を選択
3. アプリケーションのタブをリロード

初期化が完了しました！開発を開始できます。
