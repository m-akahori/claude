#!/bin/bash

# 開発環境を起動します
# 使用例: ./start-dev.sh（idolで起動）または ./start-dev.sh regrit（regritで起動）

set -e  # エラーが発生したら即座に終了

# 0. リポジトリディレクトリへ移動（デフォルト: idol）
TARGET="${1:-idol}"
cd "$TARGET" || {
  echo "エラー: ディレクトリ '$TARGET' に移動できません。"
  exit 1
}
echo "ディレクトリ: $(pwd)"

# 1. 現在のディレクトリを確認
if [ ! -f docker-compose.yml ]; then
  echo "エラー: docker-compose.ymlが見つかりません。"
  echo "Dockerプロジェクトのルートディレクトリで実行してください。"
  exit 1
fi

if [ ! -f .env ]; then
  echo "エラー: .envファイルが見つかりません。"
  echo ".env.exampleをコピーして.envファイルを作成してください。"
  exit 1
fi

# 2. 環境変数の読み込み
export $(grep -E "^(APP_NAME|APP_TLD|APP_PORT|VITE_PORT)=" .env | xargs)

# APP_URLを構築
export APP_URL="https://${APP_NAME}-local.${APP_TLD}:${APP_PORT}"
export VITE_URL="https://localhost:${VITE_PORT}"

echo "APP_URL: ${APP_URL}"
echo "VITE_URL: ${VITE_URL}"

# 3. Dockerデーモンの確認
if ! docker info > /dev/null 2>&1; then
  echo "Dockerが起動していません。Dockerを起動しています..."
  open -a Docker
  echo "Dockerの起動を待っています..."
  sleep 10
fi

# 4. Dockerコンテナの起動
echo "Dockerコンテナを起動しています..."
docker compose up -d

echo "起動状態を確認中..."
docker compose ps

# 5. 開発サーバーの起動
echo "Vite開発サーバーをバックグラウンドで起動しています..."
npm run dev &

# 6. ブラウザでアプリケーションを開く

# ステップ1: アプリケーションURLを開く
echo "アプリケーションを開いています..."
sleep 3
open "${APP_URL}"

# ステップ2: Vite開発サーバーURLを開く
echo "Vite開発サーバーURLを開いています..."
sleep 1
open "${VITE_URL}"

echo ""
echo "============================================"
echo "開発環境が正常に起動しました！"
echo "============================================"
echo ""
echo "次のステップ:"
echo "1. Vite開発サーバーのタブで「詳細設定」→「安全でないサイトに進む」を選択"
echo "2. アプリケーションのタブをリロード"
echo ""
echo "Vite接続エラーが出る場合:"
echo "1. 'npm run dev' の出力でポート番号を確認"
echo "2. https://localhost:[ポート番号] をブラウザで開く"
echo "3. 証明書を許可してから、アプリケーションをリロード"
echo ""
