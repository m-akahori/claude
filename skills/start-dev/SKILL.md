---
name: start-dev
description: Docker＋Viteの開発環境を起動してブラウザを開く
argument-hint: "[プロジェクトディレクトリ名]"
disable-model-invocation: true
allowed-tools: Bash(docker *) Bash(npm *) Bash(open *) Bash(sleep *) Bash(source *) Bash(grep *) Bash(ls *)
---

開発環境を起動します。

使用例: `/start-dev` または `/start-dev regrit`

トラブルシューティングは [troubleshooting.md](troubleshooting.md) を参照。

# 手順

## 0. リポジトリディレクトリへ移動（引数指定時のみ）

引数が指定されている場合は、そのディレクトリに移動します。

```bash
cd {{arg}}
```

引数が指定されていない場合は、現在のディレクトリで実行します。

## 1. 現在のディレクトリを確認

docker-compose.ymlファイルの存在を確認します。

```bash
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
```

## 2. 環境変数の読み込み

.envファイルから必要な環境変数を読み込みます。

```bash
source <(grep -E "^(APP_NAME|APP_TLD|APP_PORT|VITE_PORT)=" .env | sed 's/^/export /')
```

APP_URLを構築します。

```bash
export APP_URL="https://${APP_NAME}-local.${APP_TLD}:${APP_PORT}"
export VITE_URL="https://localhost:${VITE_PORT}"

echo "APP_URL: ${APP_URL}"
echo "VITE_URL: ${VITE_URL}"
```

## 3. Dockerデーモンの確認

Dockerが起動しているか確認し、起動していなければ起動します。

```bash
if ! docker info > /dev/null 2>&1; then
  echo "Dockerが起動していません。Dockerを起動しています..."
  open -a Docker
  echo "Dockerの起動を待っています..."
  sleep 10
fi
```

## 4. Dockerコンテナの起動

Docker環境を立ち上げます。

```bash
docker compose up -d
```

起動状態を確認：

```bash
docker compose ps
```

## 5. 開発サーバーの起動

Vite開発サーバーをバックグラウンドで起動します。

```bash
npm run dev &
```

または、フォアグラウンドで起動する場合：

```bash
npm run dev
```

## 6. ブラウザでアプリケーションを開く

アプリケーションURLとVite開発サーバーURLを開きます。

### ステップ1: アプリケーションURLを開く

```bash
sleep 3
open "${APP_URL}"
```

### ステップ2: Vite開発サーバーURLを開く

Vite開発サーバーの証明書を許可するため、Vite URLも開きます。

```bash
sleep 1
open "${VITE_URL}"
```

### ステップ3: 証明書を許可

Vite開発サーバーのタブで「詳細設定」→「安全でないサイトに進む」を選択して接続を許可してください。

その後、アプリケーションのタブをリロードすると、Viteが正常に接続されます。

## 7. Vite接続エラーの対処

Viteの開発サーバーに接続エラーが出る場合は、以下の手順で証明書を許可してください：

### ステップ1: Viteのポート番号を確認

`npm run dev` の出力を確認し、Viteが使用しているポート番号をチェックしてください。
通常は .env で設定した VITE_PORT ですが、ポートが使用中の場合は別のポートに自動的に変更されます。

### ステップ2: Vite開発サーバーURLにアクセス

出力に表示された `Local:` のURLをブラウザで開いてください。

例：
```bash
open "https://localhost:51732"
```

### ステップ3: 証明書を許可

ブラウザで「詳細設定」→「安全でないサイトに進む」を選択して接続を許可してください。

その後、アプリケーションURLをリロードすると、Viteが正常に接続されます。

開発環境が正常に起動しました！
