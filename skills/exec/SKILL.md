---
name: exec
description: NotionチケットのURLを引数に受け取り、記載内容を実行する
argument-hint: "<NotionチケットのURL>"
allowed-tools: mcp__notion__get-page mcp__notion__get-block-children mcp__notion__update-page mcp__notion__update-block mcp__notion__append-blocks mcp__notion__query-database Bash(git *) Bash(docker *) Bash(npm *) Bash(gh *) Bash(cd *) Bash(ls *) Bash(cat *) Bash(find *) Bash(php artisan *) Bash(composer *) Bash(vendor/bin/pint *)
---

引数に指定したNotionチケットの内容を読み込み、記載している内容を実行する。

使用例: `/exec https://www.notion.so/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

**前提**: 明記がない限り、作業対象は `idol` ディレクトリとする。

---

## Step 1: チケットの読み込みと確認

### 1-1. ページIDの抽出とページ取得

引数のURLからページIDを抽出し、`mcp__notion__get-page` でチケットを取得する。

- URLの末尾32文字（ハイフンなし）がページID
- 例: `https://www.notion.so/abc123...def456` → page_id = `abc123...def456`
- UUIDフォーマット（8-4-4-4-12）でも可

次に `mcp__notion__get-block-children` でページ本文を取得する。has_more が true の場合は next_cursor を使って全ブロックを取得すること。

### 1-2. セクション存在確認

取得した本文に以下のセクション見出し（heading_1 または heading_2）が存在するか確認する：

| セクション | 必須 |
|----------|------|
| 概要 | 必須 |
| 対応内容 | 必須 |
| 対応手順 | 必須 |
| チェックリスト | 必須 |

いずれかが欠けている場合は以下を表示して終了する：

```
エラー: チケットに必要なセクションが不足しています。
不足セクション: [不足しているセクション名]
チケットを修正してから再実行してください。
```

### 1-3. 内容の確認

以下を読み込んで整合性を確認する：

1. 「概要」セクション: このチケットで何を行うかを把握する
2. 「対応内容」セクション: as is / to be / 対応詳細を把握する
3. 「対応手順」セクション: 具体的な作業手順の番号と内容を把握する
4. 「チェックリスト」セクション: 完了条件を把握する

概要・対応内容と対応手順・チェックリストの間に明らかな不整合（全く関係ない内容など）がある場合は、その旨を報告して続行するか確認する。

### 1-4. チケットプロパティ確認

取得したページから以下の情報を確認・記録する：

| 確認項目 | プロパティ名 |
|---------|-----------|
| チケットNo | `チケットNo` |
| タイトル | ページタイトル |
| ステータス | `ステータス` |
| 親課題 | `親課題`（リレーション、存在する場合） |
| 子課題 | `子課題`（リレーション、存在する場合） |

### 1-5. ステータスの更新

チケットのステータスが `TO DO` の場合、`mcp__notion__update-page` で `進行中` に変更する。
すでに `進行中` またはその他のステータスの場合は変更しない。

---

## Step 2: コード変更の有無チェック

「概要」「対応内容」「対応手順」の内容を分析し、コード変更（ファイル編集、DB変更、コマンド実行など）が必要かどうかを判定する。

**コード変更が不要な例**: ドキュメント更新のみ、Notion上の情報整理のみ、など

### コード変更が不要な場合

Step 3（対応手順の実施）に進む。

### コード変更が必要な場合

以下を実行する：

#### 2-1. 開発環境の起動

`Skill(start-dev)` を実行して Docker ローカル開発環境を起動する。

#### 2-2. ブランチの作成

まず親課題の有無を確認する：

**【親課題がない場合】**

```bash
cd idol
git checkout master
git pull origin master
git checkout -b feature/{チケットNo}
```

ブランチ名例: `feature/42`

**【親課題がある場合 — 対象が親課題のとき】**

```bash
cd idol
git checkout master
git pull origin master
git checkout -b feature/{チケットNo}
```

ブランチ名例: `feature/10`

**【親課題がある場合 — 対象が子課題のとき】**

まず親課題のブランチが存在するか確認する：

```bash
cd idol
git branch -a | grep feature/{親チケットNo}
```

親課題ブランチが存在しない場合は先に作成する：

```bash
git checkout master
git pull origin master
git checkout -b feature/{親チケットNo}
```

その後、子課題のブランチを切る：

```bash
git checkout feature/{親チケットNo}
git checkout -b feature/{親チケットNo}/{子チケットNo}
```

ブランチ名例: `feature/10/12`

---

## Step 3: 対応手順の実施

対応手順セクションの内容を1から順番に実施する。コマンド実行が必要な場合は、対応するコンテナ内でのコマンドを優先する（例: PHP は php コンテナ、npm は node コンテナなど）。

コード修正を行う場合は、修正箇所に応じて `.claude/docs` 配下の該当するファイルの規則に遵守する。

### 各手順の実施ルール

**各手順が完了するたびに以下を行う：**

1. ユーザーに確認を求める：

```
手順 {N} 「{手順の内容}」が完了しました。
次の手順に進んでよいですか？ (y/n)
```

ユーザーが `y` を入力したら次の手順に進む。`n` の場合は「作業を一時停止しました。」と表示して終了する。

2. Notion の対応手順 {N} の番号の直下に、実施した内容を追記する（`mcp__notion__append-blocks` または `mcp__notion__update-block`）。

追記フォーマット（numbered_list_item の子ブロックとして paragraph で追記）:

```
対応記録（{YYYY-MM-DD}）: {実施した内容の要約}
```

---

## Step 4: コミット＆プッシュ

対応手順の最後の作業が完了したら、コード変更がある場合のみ以下を行う。

コード変更がない場合はこの Step をスキップして Step 5 へ進む。

### 4-1. ユーザーへの確認

```
全ての手順が完了しました。
変更内容をコミット＆プッシュしますか？ (y/n)
```

`n` の場合は「コミット・プッシュをスキップしました。」と表示して Step 5 へ進む。

### 4-2. コミット＆プッシュ

`y` の場合、以下を実行する：

```bash
cd idol
git add -A
git status
```

変更ファイルを確認し、コミットメッセージを作成してコミットする：

```bash
git commit -m "$(cat <<'EOF'
{コミットメッセージ}

対応チケット: {NotionチケットURL}

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

コミットメッセージは「{チケットNo}: {チケットタイトル}」の形式を基本とし、内容に応じて適切に記述する。

その後プッシュする：

```bash
git push origin {現在のブランチ名}
```

---

## Step 5: チェックリストのチェック

チケットの「チェックリスト」セクションの各項目を確認し、完了しているものには `mcp__notion__update-block` でチェックを入れる（`checked: true`）。

チェックできない項目がある場合は、その項目名と理由を報告する。

---

## Step 6: プルリクエストの作成

コード変更がある場合のみ実施する。コード変更がない場合はこの Step をスキップして完了メッセージを表示する。

### 6-1. マージ先ブランチの決定

| 条件 | マージ先 |
|------|---------|
| 親課題がない（最上位チケット） | `master` |
| 親課題がある（子課題） | `feature/{親チケットNo}` |

### 6-2. PR の作成

```bash
cd idol
gh pr create \
  --title "{チケットNo}: {チケットタイトル}" \
  --base {マージ先ブランチ} \
  --body "$(cat <<'EOF'
## 対応チケット

{NotionチケットURL}

## 対応概要

{このPRで何を修正したかの概要}

## 対応詳細

{修正の詳細。変更ファイルや変更理由など}

## テスト結果

{テスト結果を記載。テストを実施した場合はその結果、実施しない場合はその理由}
EOF
)"
```

PR 作成後、PR の URL を表示する。

---

## 完了メッセージ

```
/exec が完了しました。

チケット: No.{チケットNo} {チケットタイトル}
ステータス: 進行中
{コード変更がある場合のみ↓}
ブランチ: {ブランチ名}
PR: {PR URL}
```
