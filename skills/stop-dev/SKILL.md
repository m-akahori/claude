---
name: stop-dev
description: Docker＋Viteの開発環境を停止する
argument-hint: "[プロジェクトディレクトリ名]"
disable-model-invocation: true
allowed-tools: Bash(docker *) Bash(pkill *) Bash(kill *) Bash(ps *)
---

開発環境を停止します。

使用例: `/stop-dev` または `/stop-dev regrit`

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
```

## 2. 起動中のコンテナを確認

現在起動中のコンテナを確認します。

```bash
docker compose ps
```

## 3. Vite開発サーバーの停止

npm run devで起動したViteプロセスを停止します。

### 方法1: プロセスを検索して停止

```bash
VITE_PID=$(ps aux | grep "vite" | grep -v grep | awk '{print $2}')

if [ -n "$VITE_PID" ]; then
  echo "Vite開発サーバーを停止しています... (PID: $VITE_PID)"
  kill $VITE_PID
  echo "Vite開発サーバーを停止しました。"
else
  echo "実行中のVite開発サーバーが見つかりませんでした。"
fi
```

### 方法2: 手動停止の案内

バックグラウンドで実行している場合は、ターミナルでCtrl+Cを押すか、以下のコマンドで停止してください：

```bash
pkill -f "vite"
```

## 4. Dockerコンテナの停止

Docker環境を停止します。

```bash
docker compose down
```

完全にクリーンアップする場合（ボリュームも削除）：

```bash
docker compose down -v
```

## 5. ブラウザのタブを閉じる

開いているアプリケーションとVite開発サーバーのブラウザタブを手動で閉じてください。

開発環境を停止しました！
