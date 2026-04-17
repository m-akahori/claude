#!/bin/bash

# 新規クローンしたLaravelプロジェクトをローカル環境で開発できるように初期化します
# ゴール: HTTPSで独自ドメインでブラウザに接続でき、新しいプロジェクトがローカル環境で開発開始できるようになること

set -e  # エラーが発生したら即座に終了

echo "============================================"
echo "Laravelプロジェクト初期化スクリプト"
echo "============================================"
echo ""

# 1. プロジェクト固有設定の入力
echo "プロジェクト固有設定を入力してください："
echo ""

read -p "APP_NAME (プロジェクト名、例: regrit, idol): " APP_NAME
read -p "APP_TLD (トップレベルドメイン、例: co.jp, com): " APP_TLD

if [ -z "$APP_NAME" ] || [ -z "$APP_TLD" ]; then
  echo "エラー: APP_NAMEとAPP_TLDは必須です。"
  exit 1
fi

echo ""
echo "設定内容:"
echo "  APP_NAME: ${APP_NAME}"
echo "  APP_TLD: ${APP_TLD}"
echo ""

# 2. .envファイルの作成
echo "Step 1/12: .envファイルを作成しています..."

if [ ! -f .env.local ]; then
  echo "エラー: .env.localファイルが見つかりません。"
  exit 1
fi

cp .env.local .env
echo ".envファイルを作成しました。"

# 2-1. APP_NAMEとAPP_TLDの設定
echo "Step 2/12: APP_NAMEとAPP_TLDを設定しています..."

sed -i '' "s/^APP_NAME=.*/APP_NAME=${APP_NAME}/" .env
sed -i '' "s/^APP_TLD=.*/APP_TLD=${APP_TLD}/" .env
sed -i '' "s/^APP_NAME=.*/APP_NAME=${APP_NAME}/" .env.local
sed -i '' "s/^APP_TLD=.*/APP_TLD=${APP_TLD}/" .env.local

echo "APP_NAMEとAPP_TLDを設定しました。"

# 2-2. ポート番号の自動調整
echo "Step 3/12: ポート番号を調整しています..."

# デフォルトポートに+1した値を提案
NEW_APP_PORT=4432
NEW_DB_PORT=33017
NEW_MAILHOG_PORT=1252
NEW_MAILHOG_WEB=8252
NEW_VITE_PORT=51732

echo "提案されたポート番号:"
echo "  APP_PORT: ${NEW_APP_PORT}"
echo "  DB_LOCAL_PORT: ${NEW_DB_PORT}"
echo "  MAILHOG_LOCAL_PORT: ${NEW_MAILHOG_PORT}"
echo "  MAILHOG_WEB_PORT: ${NEW_MAILHOG_WEB}"
echo "  VITE_PORT: ${NEW_VITE_PORT}"
echo ""

# ポート使用状況の確認
echo "ポート使用状況を確認しています..."
lsof -i :${NEW_APP_PORT} 2>/dev/null && echo "警告: ポート ${NEW_APP_PORT} は使用中です" || echo "ポート ${NEW_APP_PORT} は利用可能"
lsof -i :${NEW_DB_PORT} 2>/dev/null && echo "警告: ポート ${NEW_DB_PORT} は使用中です" || echo "ポート ${NEW_DB_PORT} は利用可能"
lsof -i :${NEW_VITE_PORT} 2>/dev/null && echo "警告: ポート ${NEW_VITE_PORT} は使用中です" || echo "ポート ${NEW_VITE_PORT} は利用可能"
echo ""

read -p "この設定でポート番号を更新しますか？ (y/n): " UPDATE_PORTS

if [ "$UPDATE_PORTS" = "y" ] || [ "$UPDATE_PORTS" = "Y" ]; then
  sed -i '' "s/^APP_PORT=.*/APP_PORT=${NEW_APP_PORT}/" .env
  sed -i '' "s/^DB_LOCAL_PORT=.*/DB_LOCAL_PORT=${NEW_DB_PORT}/" .env
  sed -i '' "s/^MAILHOG_LOCAL_PORT=.*/MAILHOG_LOCAL_PORT=${NEW_MAILHOG_PORT}/" .env
  sed -i '' "s/^MAILHOG_WEB_PORT=.*/MAILHOG_WEB_PORT=${NEW_MAILHOG_WEB}/" .env
  sed -i '' "s/^VITE_PORT=.*/VITE_PORT=${NEW_VITE_PORT}/" .env

  sed -i '' "s/^APP_PORT=.*/APP_PORT=${NEW_APP_PORT}/" .env.local
  sed -i '' "s/^DB_LOCAL_PORT=.*/DB_LOCAL_PORT=${NEW_DB_PORT}/" .env.local
  sed -i '' "s/^MAILHOG_LOCAL_PORT=.*/MAILHOG_LOCAL_PORT=${NEW_MAILHOG_PORT}/" .env.local
  sed -i '' "s/^MAILHOG_WEB_PORT=.*/MAILHOG_WEB_PORT=${NEW_MAILHOG_WEB}/" .env.local
  sed -i '' "s/^VITE_PORT=.*/VITE_PORT=${NEW_VITE_PORT}/" .env.local

  echo "ポート番号を更新しました。"
else
  echo "ポート番号の更新をスキップしました。"
fi

# 環境変数を読み込み
export $(grep -E "^(APP_NAME|APP_TLD|APP_PORT|VITE_PORT)=" .env | xargs)

# 3. hostsファイルにドメインを追加
echo ""
echo "Step 4/12: /etc/hostsにドメインを追加します..."
echo "以下の行を /etc/hosts に追加する必要があります:"
echo "  127.0.0.1 ${APP_NAME}-local.${APP_TLD}"
echo ""
echo "sudo権限が必要です。"

read -p "/etc/hostsに追加しますか？ (y/n): " ADD_HOSTS

if [ "$ADD_HOSTS" = "y" ] || [ "$ADD_HOSTS" = "Y" ]; then
  # 既に存在するかチェック
  if grep -q "${APP_NAME}-local.${APP_TLD}" /etc/hosts 2>/dev/null; then
    echo "既に /etc/hosts に存在します。スキップします。"
  else
    echo "127.0.0.1 ${APP_NAME}-local.${APP_TLD}" | sudo tee -a /etc/hosts > /dev/null
    echo "/etc/hosts に追加しました。"
  fi
else
  echo "/etc/hosts への追加をスキップしました。"
  echo "後で手動で追加してください："
  echo "  sudo nano /etc/hosts"
  echo "  # 以下の行を追加："
  echo "  127.0.0.1 ${APP_NAME}-local.${APP_TLD}"
fi

# 4. Composer依存関係のインストール
echo ""
echo "Step 5/12: Composer依存関係をインストールしています..."
composer install

# 5. Node.js依存関係のインストール
echo ""
echo "Step 6/12: npm依存関係をインストールしています..."
npm install

# 6. Dockerコンテナの起動
echo ""
echo "Step 7/12: Dockerコンテナを起動しています..."

# Dockerデーモンの確認
if ! docker info > /dev/null 2>&1; then
  echo "Dockerが起動していません。Dockerを起動しています..."
  open -a Docker
  echo "Dockerの起動を待っています..."
  sleep 10
fi

docker compose up -d

echo "コンテナの起動状態を確認しています..."
docker compose ps

# 7. アプリケーションキーの生成
echo ""
echo "Step 8/12: アプリケーションキーを生成しています..."
docker compose exec php-fpm php artisan key:generate

# 8. データベースマイグレーション
echo ""
echo "Step 9/12: データベースマイグレーションを実行しています..."
docker compose exec php-fpm php artisan migrate

# 9. データベースシーダーの実行
echo ""
echo "Step 10/12: データベースシーダーを実行しています..."

read -p "シーダーを実行しますか？ (y/n): " RUN_SEEDER

if [ "$RUN_SEEDER" = "y" ] || [ "$RUN_SEEDER" = "Y" ]; then
  docker compose exec php-fpm php artisan db:seed || echo "シーダーが存在しないか、エラーが発生しました。"
else
  echo "シーダーの実行をスキップしました。"
fi

# 10. Vite用SSL証明書の生成
echo ""
echo "Step 11/12: Vite用SSL証明書を生成しています..."

if [ -f ./update-dev-certs.sh ]; then
  APP_NAME="${APP_NAME}" APP_TLD="${APP_TLD}" ./update-dev-certs.sh
  echo "SSL証明書を生成しました。"
else
  echo "警告: update-dev-certs.sh が見つかりません。"
  echo "SSL証明書の生成をスキップします。"
  echo "HTTPSでViteを起動するには、証明書が必要です。"
fi

# 11. Vite開発サーバーの起動
echo ""
echo "Step 12/12: Vite開発サーバーを起動しています..."
npm run dev &

# 12. ブラウザでアプリケーションを開く
echo ""
echo "ブラウザでアプリケーションを開いています..."

export APP_URL="https://${APP_NAME}-local.${APP_TLD}:${APP_PORT}"
export VITE_URL="https://localhost:${VITE_PORT}"

sleep 3
open "${APP_URL}"
sleep 1
open "${VITE_URL}"

echo ""
echo "============================================"
echo "初期化が完了しました！開発を開始できます。"
echo "============================================"
echo ""
echo "次のステップ:"
echo "1. Vite開発サーバーのタブで「詳細設定」→「安全でないサイトに進む」を選択"
echo "2. アプリケーションのタブで「詳細設定」→「安全でないサイトに進む」を選択"
echo "3. アプリケーションのタブをリロード"
echo ""
echo "アクセスURL:"
echo "  アプリケーション: ${APP_URL}"
echo "  Vite開発サーバー: ${VITE_URL}"
echo ""
