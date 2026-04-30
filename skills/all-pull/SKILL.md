---
name: all-pull
description: 全gitリポジトリ（startup/diet/.claude/idol）をベースブランチに切り替えて最新化する。「pull」「最新化」「git更新」と言われたときに使う。
disable-model-invocation: true
allowed-tools: Bash(git *)
---

以下の4つのgitリポジトリを順番に最新化する。

| リポジトリ | パス | ベースブランチ |
|----------|------|-------------|
| startup | /Users/akahori_mitsuru/mydev/startup | main |
| diet | /Users/akahori_mitsuru/mydev/diet | main |
| .claude | /Users/akahori_mitsuru/mydev/.claude | main |
| idol | /Users/akahori_mitsuru/mydev/idol | master |

以下のBashコマンドを1回で実行すること:

```bash
for entry in "startup:main" "diet:main" ".claude:main" "idol:master"; do
  repo="${entry%%:*}"
  branch="${entry##*:}"
  path="/Users/akahori_mitsuru/mydev/$repo"
  echo "=== $repo ==="
  git -C "$path" checkout "$branch" 2>&1
  git -C "$path" \
    -c credential.helper= \
    -c "url.https://${PB_USER_NAME}:${PB_GIT_PAT}@github.com/.insteadOf=https://github.com/" \
    -c "url.https://${PB_USER_NAME}:${PB_GIT_PAT}@github.com/.insteadOf=https://m-akahori@github.com/" \
    pull origin "$branch" 2>&1
  echo ""
done
```

各リポジトリの結果を報告すること。成功したら「✓ <リポジトリ名>: 最新化完了」、エラーがあれば内容を表示する。
