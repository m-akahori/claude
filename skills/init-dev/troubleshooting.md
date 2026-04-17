# init-dev トラブルシューティング

## ポート競合が発生した場合

別のプロジェクトでポートが使用されている場合は、さらに+1した値を試してください。

```bash
lsof -i :{ポート番号}
kill -9 {プロセスID}
```

## データベース接続エラーが発生した場合

```bash
docker compose ps
docker compose logs mariadb
```

## npm run devが失敗する場合

```bash
rm -rf node_modules
npm install
npm run dev
```

## ERR_SSL_PROTOCOL_ERRORが発生する場合

**原因**: SSL証明書が存在せず、ViteサーバーがHTTPで起動しているのにHTTPSのURLでアクセスしている。

**解決策**:

1. Viteサーバーを停止する（Ctrl+C またはバックグラウンドタスクをkill）

2. SSL証明書を生成する：

```bash
APP_NAME={APP_NAME} APP_TLD={APP_TLD} ./update-dev-certs.sh
```

3. ViteサーバーをHTTPSで再起動する：

```bash
npm run dev
```

4. `https://` で起動していることを確認。`http://` の場合は証明書生成に失敗しています。

## SSL証明書生成スクリプトが失敗する場合

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

環境変数を設定せずに実行するとコンテナ名が正しく検出できません。
