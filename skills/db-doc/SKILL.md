---
name: db-doc
description: 現在のmigrationファイルに基づいてDBドキュメント（DB定義書・ER図・DFD）を生成・更新する
argument-hint: "[プロジェクト名（省略時: idol）]"
disable-model-invocation: true
allowed-tools: Bash(ls *) Bash(find *) Bash(mkdir *) Read Write Edit
---

# DB ドキュメント生成スキル

## 対象プロジェクトの決定

引数 `$ARGUMENTS` をプロジェクト名として使用する。未指定の場合は `idol` を使用する。

```
プロジェクト名: $ARGUMENTS（未指定時は idol）
プロジェクトルート: /Users/akahori_mitsuru/mydev/<プロジェクト名>
```

## 除外テーブル

以下のテーブルはドキュメント対象外とする:
- `users`
- `cache` / `cache_locks`
- `jobs` / `job_batches` / `failed_jobs`
- `personal_access_tokens`
- `sessions`
- `password_reset_tokens`

## 手順

### Step 1: マイグレーションファイルの読み込み

`<プロジェクトルート>/database/migrations/` 配下の全 `.php` ファイルを読み込む。
除外テーブルに関するマイグレーション（ファイル名に `users`, `cache`, `jobs`, `personal_access_token`, `session`, `password` を含むもの）はスキップする。

### Step 2: テーブル情報の解析

各マイグレーションファイルから以下を抽出する:
- テーブル名
- カラム名・データ型・NULL許容・デフォルト値・説明
- PRIMARY KEY
- UNIQUE KEY / UNIQUE インデックス
- 通常インデックス（INDEX）
- 外部キー制約（参照先テーブル・カラム・ON DELETE アクション）

### Step 3: 出力ディレクトリの準備

`<プロジェクトルート>/docs/database/` ディレクトリが存在しない場合は作成する。

### Step 4: ① DB定義書の生成・更新

ファイルパス: `<プロジェクトルート>/docs/database/db-definition.md`

**ファイルが存在しない場合:** 以下の構成で新規作成する。
**ファイルが存在する場合:** 現状の migration ファイルと比較し、差分がある部分のみ更新する。

#### ファイル構成

```markdown
# DB定義書

最終更新: YYYY-MM-DD

## 目次

- [テーブル名A](#テーブル名a)
- [テーブル名B](#テーブル名b)
...

---

## テーブル名A

> テーブルの用途を1行で説明

### カラム定義

| カラム名 | データ型 | NULL | デフォルト | キー | 説明 |
|---------|---------|------|----------|------|------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | 主キー |
| ... | ... | ... | ... | ... | ... |
| created_at | TIMESTAMP | YES | NULL | - | 作成日時 |
| updated_at | TIMESTAMP | YES | NULL | - | 更新日時 |

### インデックス

| インデックス名 | 種別 | カラム |
|-------------|------|-------|
| PRIMARY | PRIMARY KEY | id |
| ... | UNIQUE / INDEX | ... |

### 外部キー制約

| カラム | 参照先 | ON DELETE |
|-------|-------|-----------|
| xxx_id | テーブル名(id) | CASCADE / SET NULL / RESTRICT |

---
（次のテーブルへ続く）
```

目次のリンクは GitHub Flavored Markdown のアンカー形式（小文字・スペースはハイフン）で生成する。

### Step 5: ② ER図・DFD の生成・更新

ファイルパス: `<プロジェクトルート>/docs/database/er-dfd.md`

**ファイルが存在しない場合:** 以下の構成で新規作成する。
**ファイルが存在する場合:** migration の変更に合わせて差分更新する。

#### ファイル構成

```markdown
# ER図・データフロー図（DFD）

最終更新: YYYY-MM-DD

## ER図

\`\`\`mermaid
erDiagram
    テーブルA {
        bigint id PK
        string name
        ...
        timestamp created_at
        timestamp updated_at
    }
    テーブルB {
        ...
    }
    中間テーブル {
        ...
    }

    テーブルA ||--o{ 中間テーブル : "has"
    テーブルB ||--o{ 中間テーブル : "has"
    テーブルA ||--o{ テーブルC : "belongs to"
\`\`\`

## DFD（データフロー図）

\`\`\`mermaid
flowchart TD
    （ユーザー操作・APIリクエストの流れをエンティティとテーブルの関係として図示）
\`\`\`
```

#### ER図のルール
- 除外テーブルは含めない
- 外部キー制約に基づいてリレーションを `||--o{` 等で表現する
- 多対多の中間テーブルは両端のテーブルと接続する
- カラムは型を mermaid の erDiagram 形式（`string`, `bigint`, `datetime`, `text`, `boolean` 等）で記載する

#### DFD のルール
- アクター（ユーザー、管理者等）→ 処理 → テーブル の流れを `flowchart TD` で表現する
- `.claude/docs/8_database_design.md` の 7.2.3 節を参考にする

### Step 6: 完了報告

以下を報告する:
- 生成・更新したファイルのパス
- 対象テーブル一覧
- 新規作成か差分更新かの区別
