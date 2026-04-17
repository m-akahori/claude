開発環境を停止します。

使用例: `/stop-dev` または `/stop-dev regrit`

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
# Viteプロセスを検索
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
# Viteプロセスをすべて停止
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

## トラブルシューティング

### Viteプロセスが停止しない場合

```bash
# すべてのnodeプロセスを確認
ps aux | grep node

# 特定のPIDを強制終了
kill -9 <PID>
```

### Dockerコンテナが停止しない場合

```bash
# 実行中のコンテナを確認
docker compose ps

# 強制停止
docker compose kill

# コンテナを削除
docker compose rm -f
```

### ポートが使用中のまま残っている場合

```bash
# 特定のポートを使用しているプロセスを確認
lsof -i :4431    # アプリケーションポート
lsof -i :51731   # Viteポート
lsof -i :33016   # MariaDBポート

# プロセスを停止
kill -9 <PID>
```

開発環境を停止しました！
