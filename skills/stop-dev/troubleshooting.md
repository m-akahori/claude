# stop-dev トラブルシューティング

## Viteプロセスが停止しない場合

```bash
# すべてのnodeプロセスを確認
ps aux | grep node

# 特定のPIDを強制終了
kill -9 <PID>
```

## Dockerコンテナが停止しない場合

```bash
# 実行中のコンテナを確認
docker compose ps

# 強制停止
docker compose kill

# コンテナを削除
docker compose rm -f
```

## ポートが使用中のまま残っている場合

```bash
# 特定のポートを使用しているプロセスを確認
lsof -i :4431    # アプリケーションポート
lsof -i :51731   # Viteポート
lsof -i :33016   # MariaDBポート

# プロセスを停止
kill -9 <PID>
```
