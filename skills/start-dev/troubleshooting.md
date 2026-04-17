# start-dev トラブルシューティング

## Dockerデーモンが起動しない場合

```bash
# Dockerアプリを手動で開く
open -a Docker

# Dockerの状態を確認
docker info
```

## Dockerコンテナが起動しない場合

```bash
docker compose ps
docker compose logs
```

## npm run devが失敗する場合

```bash
# 依存関係を再インストール
npm install

# キャッシュをクリアして再起動
rm -rf node_modules/.vite
npm run dev
```

## ポートが既に使用されている場合

`.env`ファイルで以下のポートを確認・変更してください：
- `APP_PORT`: アプリケーションポート
- `VITE_PORT`: Vite開発サーバーポート
- `DB_LOCAL_PORT`: MariaDBポート

```bash
# 特定のポートを使用しているプロセスを確認
lsof -i :4431    # アプリケーションポート
lsof -i :51731   # Viteポート
lsof -i :33016   # MariaDBポート

# プロセスを停止
kill -9 <PID>
```
