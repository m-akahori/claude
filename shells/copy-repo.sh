#!/bin/bash

# Gitリポジトリをコピーして新しいプロジェクトを作成します
# 使用例: ./copy-repo.sh <元のリポジトリ名> <新しいリポジトリ名>
# 例: ./copy-repo.sh regrit idol

set -e  # エラーが発生したら即座に終了

# 0. 引数の確認
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "エラー: 引数が不足しています。"
  echo "使用例: ./copy-repo.sh <元のリポジトリ名> <新しいリポジトリ名>"
  exit 1
fi

SOURCE_REPO="$1"
TARGET_REPO="$2"

echo "元のリポジトリ: ${SOURCE_REPO}"
echo "新しいリポジトリ: ${TARGET_REPO}"

# 1. 元のリポジトリの存在確認
if [ ! -d "${SOURCE_REPO}" ]; then
  echo "エラー: 元のリポジトリ '${SOURCE_REPO}' が見つかりません。"
  exit 1
fi

# 2. 新しいリポジトリの存在確認
if [ -d "${TARGET_REPO}" ]; then
  echo "エラー: '${TARGET_REPO}' は既に存在します。"
  echo "別の名前を指定するか、既存のディレクトリを削除してください。"
  exit 1
fi

# 3. リポジトリのコピー
echo "リポジトリをコピーしています..."
cp -R "${SOURCE_REPO}" "${TARGET_REPO}"
echo "コピーが完了しました。"

# 4. Gitディレクトリの削除
cd "${TARGET_REPO}"
rm -rf .git
echo ".gitディレクトリを削除しました。"

# 5. 環境変数ファイルの更新
if [ -f .env ]; then
  sed -i '' "s/^APP_NAME=.*/APP_NAME=${TARGET_REPO}/" .env
  echo ".envファイルのAPP_NAMEを更新しました。"
fi

if [ -f .env.local ]; then
  sed -i '' "s/^APP_NAME=.*/APP_NAME=${TARGET_REPO}/" .env.local
  echo ".env.localファイルのAPP_NAMEを更新しました。"
fi

# 6. ポート番号の更新（オプション）
echo ""
echo "注意: ポート番号が元のリポジトリと重複しています。"
echo "以下のポート番号を変更することをお勧めします："
echo "  - APP_PORT: アプリケーションポート"
echo "  - DB_LOCAL_PORT: MariaDBポート"
echo "  - MAILHOG_LOCAL_PORT: MailHogポート"
echo "  - MAILHOG_WEB_PORT: MailHog Webポート"
echo "  - VITE_PORT: Vite開発サーバーポート"
echo ""
echo ".envファイルを編集してください。"

# 7. 依存関係のインストール
echo ""
read -p "依存関係をインストールしますか？ (y/n): " INSTALL_DEPS

if [ "$INSTALL_DEPS" = "y" ] || [ "$INSTALL_DEPS" = "Y" ]; then
  echo "Composer依存関係をインストールしています..."
  composer install

  echo "npm依存関係をインストールしています..."
  npm install

  echo "依存関係のインストールが完了しました。"
else
  echo "依存関係のインストールをスキップしました。"
  echo "後で以下のコマンドを実行してください："
  echo "  composer install"
  echo "  npm install"
fi

# 8. アプリケーションキーの生成
echo ""
read -p "新しいアプリケーションキーを生成しますか？ (y/n): " GENERATE_KEY

if [ "$GENERATE_KEY" = "y" ] || [ "$GENERATE_KEY" = "Y" ]; then
  php artisan key:generate
  echo "アプリケーションキーを生成しました。"
else
  echo "アプリケーションキーの生成をスキップしました。"
  echo "後で以下のコマンドを実行してください："
  echo "  php artisan key:generate"
fi

# 9. Gitリポジトリの初期化
echo ""
read -p "新しいGitリポジトリとして初期化しますか？ (y/n): " INIT_GIT

if [ "$INIT_GIT" = "y" ] || [ "$INIT_GIT" = "Y" ]; then
  git init
  git add .
  git commit -m "Initial commit from ${SOURCE_REPO}"
  echo "Gitリポジトリを初期化しました。"
else
  echo "Gitリポジトリの初期化をスキップしました。"
  echo "後で以下のコマンドを実行してください："
  echo "  git init"
  echo "  git add ."
  echo "  git commit -m 'Initial commit'"
fi

# 10. 次のステップ
echo ""
echo "============================================"
echo "リポジトリのコピーが完了しました！"
echo "============================================"
echo ""
echo "次のステップ："
echo "1. .envファイルを編集してポート番号を変更"
echo "2. 開発環境を起動: ./start-dev.sh ${TARGET_REPO}"
echo "3. データベースマイグレーション: php artisan migrate"
echo "4. 必要に応じてシーダーを実行: php artisan db:seed"
echo ""
