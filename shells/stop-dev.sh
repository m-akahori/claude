#!/bin/bash

# 開発環境を停止します
# 使用例: ./stop-dev.sh（idolを停止）または ./stop-dev.sh regrit（regritを停止）

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

# 2. 起動中のコンテナを確認
echo "起動中のコンテナを確認しています..."
docker compose ps

# 3. Vite開発サーバーの停止

# Viteプロセスを検索
VITE_PID=$(ps aux | grep "vite" | grep -v grep | awk '{print $2}')

if [ -n "$VITE_PID" ]; then
  echo "Vite開発サーバーを停止しています... (PID: $VITE_PID)"
  kill $VITE_PID 2>/dev/null || true
  echo "Vite開発サーバーを停止しました。"
else
  echo "実行中のVite開発サーバーが見つかりませんでした。"
fi

# 4. Dockerコンテナの停止

echo "Dockerコンテナを停止しています..."
docker compose down

echo ""
echo "============================================"
echo "開発環境を停止しました！"
echo "============================================"
echo ""
echo "完全にクリーンアップする場合（ボリュームも削除）:"
echo "  docker compose down -v"
echo ""
echo "ブラウザのタブを手動で閉じてください。"
echo ""
