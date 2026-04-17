---
description: 新規クローンしたLaravelプロジェクトをローカル環境で開発できるように初期化します
---

GitリポジトリからクローンしたLaravelプロジェクトをローカル環境で開発開始できる状態にします。

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
# .envファイルを編集
sed -i '' "s/^APP_NAME=.*/APP_NAME={ユーザー入力のAPP_NAME}/" .env
sed -i '' "s/^APP_TLD=.*/APP_TLD={ユーザー入力のAPP_TLD}/" .env

# .env.localファイルも同様に編集
sed -i '' "s/^APP_NAME=.*/APP_NAME={ユーザー入力のAPP_NAME}/" .env.local
sed -i '' "s/^APP_TLD=.*/APP_TLD={ユーザー入力のAPP_TLD}/" .env.local
```

### 2-2. ポート番号の自動調整

他のプロジェクトとポート競合を避けるため、以下のポート番号を+1した値を提案します：

- APP_PORT（デフォルト: 4431 → 4432）
- DB_LOCAL_PORT（デフォルト: 33016 → 33017）
- MAILHOG_LOCAL_PORT（デフォルト: 1251 → 1252）
- MAILHOG_WEB_PORT（デフォルト: 8251 → 8252）
- VITE_PORT（デフォルト: 51731 → 51732）

各ポートが使用されているか確認します：

```bash
# ポート使用状況の確認
lsof -i :4432  # APP_PORT
lsof -i :33017 # DB_LOCAL_PORT
lsof -i :1252  # MAILHOG_LOCAL_PORT
lsof -i :8252  # MAILHOG_WEB_PORT
lsof -i :51732 # VITE_PORT
```

問題がなければ、.envと.env.localに反映します：

```bash
# .envファイルを編集
sed -i '' "s/^APP_PORT=.*/APP_PORT=4432/" .env
sed -i '' "s/^DB_LOCAL_PORT=.*/DB_LOCAL_PORT=33017/" .env
sed -i '' "s/^MAILHOG_LOCAL_PORT=.*/MAILHOG_LOCAL_PORT=1252/" .env
sed -i '' "s/^MAILHOG_WEB_PORT=.*/MAILHOG_WEB_PORT=8252/" .env
sed -i '' "s/^VITE_PORT=.*/VITE_PORT=51732/" .env

# .env.localファイルも同様に編集
sed -i '' "s/^APP_PORT=.*/APP_PORT=4432/" .env.local
sed -i '' "s/^DB_LOCAL_PORT=.*/DB_LOCAL_PORT=33017/" .env.local
sed -i '' "s/^MAILHOG_LOCAL_PORT=.*/MAILHOG_LOCAL_PORT=1252/" .env.local
sed -i '' "s/^MAILHOG_WEB_PORT=.*/MAILHOG_WEB_PORT=8252/" .env.local
sed -i '' "s/^VITE_PORT=.*/VITE_PORT=51732/" .env.local
```

## 3. hostsファイルにドメインを追加

localhostや127.0.0.1以外でもアクセスできるよう、/etc/hostsにドメインを追加します。

```bash
# 管理者権限でhostsファイルを編集
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

Dockerコンテナ起動前にホストマシンで実行します。

```bash
npm install
```

## 6. Dockerコンテナの起動

Docker環境を立ち上げます。

```bash
docker compose up -d
```

コンテナが正常に起動したことを確認：

```bash
docker compose ps
```

## 7. アプリケーションキーの生成

Dockerコンテナ内でartisanコマンドを実行します。

```bash
docker compose exec php-fpm php artisan key:generate
```

## 8. データベースマイグレーション

Dockerコンテナ内でマイグレーションを実行します。

```bash
docker compose exec php-fpm php artisan migrate
```

## 9. データベースシーダーの実行

初期データを投入します。

```bash
docker compose exec php-fpm php artisan db:seed
```

シーダーが存在しない場合はスキップしてください。

## 10. Vite用SSL証明書の生成

Dockerコンテナ起動後、ViteサーバーをHTTPSで起動するためにSSL証明書を生成します。

**重要**: `update-dev-certs.sh` スクリプトは環境変数 `APP_NAME` と `APP_TLD` を使用するため、実行時に環境変数を設定する必要があります。

```bash
APP_NAME={ユーザー入力のAPP_NAME} APP_TLD={ユーザー入力のAPP_TLD} ./update-dev-certs.sh
```

例：
```bash
APP_NAME=idol-ichiban APP_TLD=com ./update-dev-certs.sh
```

正常に完了すると、以下のようなメッセージが表示されます：

```
✅ Certificates updated successfully!
📁 Certificate: ./dev-certs/{APP_NAME}-local.{APP_TLD}.pem
🔑 Private key: ./dev-certs/{APP_NAME}-local.{APP_TLD}-key.pem
```

このステップにより、Nginxコンテナで生成された自己署名SSL証明書が `dev-certs/` ディレクトリにコピーされ、ViteサーバーがHTTPSで起動できるようになります。

## 11. Vite開発サーバーの起動

SSL証明書を生成した後、Vite開発サーバーを起動します。

```bash
npm run dev
```

ViteサーバーがHTTPSで起動したことを確認してください：

```
➜  Local:   https://localhost:{VITE_PORT}/
➜  Local:   https://{APP_NAME}-local.{APP_TLD}:{VITE_PORT}/
```

**注意**: もし `http://` で起動している場合は、SSL証明書が正しく生成されていません。手順10に戻って証明書を生成してください。

## 12. ブラウザでアプリケーションを開く

### ステップ1: アプリケーションURLを開く

```bash
open "https://{APP_NAME}-local.{APP_TLD}:{APP_PORT}"
```

例：
```bash
open "https://idol-local.co.jp:4432"
```

### ステップ2: Vite開発サーバーURLを開く

Vite開発サーバーの証明書を許可するため、Vite URLも開きます。
`npm run dev` の出力から実際のポート番号を確認してください。

```bash
open "https://localhost:{VITE_PORT}"
```

例：
```bash
open "https://localhost:51732"
```

### ステップ3: 証明書を許可

1. Vite開発サーバーのタブで「詳細設定」→「安全でないサイトに進む」を選択
2. アプリケーションのタブで「詳細設定」→「安全でないサイトに進む」を選択
3. アプリケーションのタブをリロード

これで、HTTPSで独自ドメインでアプリケーションにアクセスできるようになりました！

## トラブルシューティング

### ポート競合が発生した場合

別のプロジェクトでポートが使用されている場合は、さらに+1した値を試してください。

```bash
# 使用中のポートを確認
lsof -i :{ポート番号}

# 該当プロセスを停止する場合
kill -9 {プロセスID}
```

### データベース接続エラーが発生した場合

Dockerコンテナが正常に起動しているか確認してください。

```bash
docker compose ps
docker compose logs mariadb
```

### npm run devが失敗する場合

node_modulesを削除して再インストールしてください。

```bash
rm -rf node_modules
npm install
npm run dev
```

### ERR_SSL_PROTOCOL_ERRORが発生する場合

ViteサーバーにHTTPSでアクセスしようとして `ERR_SSL_PROTOCOL_ERROR` が発生する場合、SSL証明書が生成されていない可能性があります。

**原因**: SSL証明書が存在しないため、ViteサーバーがHTTPで起動しているのに、HTTPSのURLでアクセスしようとしている。

**解決策**:

1. Viteサーバーを停止する（Ctrl+Cまたはバックグラウンドタスクをkill）

2. SSL証明書を生成する：

```bash
APP_NAME={ユーザー入力のAPP_NAME} APP_TLD={ユーザー入力のAPP_TLD} ./update-dev-certs.sh
```

3. ViteサーバーをHTTPSで再起動する：

```bash
npm run dev
```

4. ViteサーバーがHTTPSで起動していることを確認する：

```
➜  Local:   https://localhost:{VITE_PORT}/
```

`https://` で起動していれば成功です。`http://` の場合は、証明書生成に失敗しています。

### SSL証明書生成スクリプトが失敗する場合

`update-dev-certs.sh` の実行時にエラーが発生する場合：

**エラー例**: `Error: -nginx container is not running.`

**原因**: Dockerコンテナが起動していないか、環境変数が設定されていない。

**解決策**:

1. Dockerコンテナが起動していることを確認：

```bash
docker compose ps
```

2. 環境変数を正しく設定してスクリプトを実行：

```bash
APP_NAME=idol-ichiban APP_TLD=com ./update-dev-certs.sh
```

環境変数を設定せずに実行すると、コンテナ名が正しく検出できません。

---

初期化が完了しました！開発を開始できます。
