# copy-repo トラブルシューティング

## コピー後にパーミッションエラーが発生する場合

```bash
cd "${TARGET_REPO}"
chmod -R 755 storage bootstrap/cache
```

## composer installが失敗する場合

```bash
# Composerをアップデート
composer self-update

# 依存関係を再インストール
rm -rf vendor
composer install
```

## npm installが失敗する場合

```bash
# node_modulesを削除して再インストール
rm -rf node_modules package-lock.json
npm install
```
