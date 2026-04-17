# Laravel 機能開発 決定フローチャート

```
START
│
▼
【1. 機能種別】
├─ 画面（Web UI）
├─ API（JSON）
├─ バッチ／スケジュール
└─ 非同期ジョブ（Queue）
│
▼
【2. DB仕様】※全種別共通
├─ 新規テーブルが必要か？
│   └─ YES → カラム / 型 / インデックス / マイグレーション設計
├─ 既存テーブルを変更するか？
│   └─ YES → ALTER内容 / 既存データへの影響確認
└─ リレーション（hasMany / belongsTo等）
│
▼
【3. 認証・認可】※全種別共通
├─ 認証が必要か？（auth ミドルウェア）
└─ 認可が必要か？（Policy / Gate）
│
▼
【種別ごとの分岐】
│
├─ ■ 画面（Web UI）
│   ├─ ルーティング：URI / HTTPメソッド / 名前付きルート
│   ├─ コントローラー：Resource？ Single Action？
│   ├─ リクエスト処理：FormRequest（バリデーション）
│   ├─ ビジネスロジック：Service層を切るか？
│   ├─ フロントエンド：Blade / Livewire / Vue・React（Inertia）
│   ├─ レスポンス：View返却 / Redirect / JSON混在？
│   └─ テスト：Feature Test（HTTP） / Browser Test
│
├─ ■ API（JSON）
│   ├─ エンドポイント：URI / HTTPメソッド / バージョニング
│   ├─ 認証方式：Sanctum / なし
│   ├─ リクエスト仕様：FormRequest / バリデーションルール
│   ├─ レスポンス仕様：API Resource / Collection
│   ├─ エラーレスポンス：形式統一（Handler.php）
│   └─ テスト：Feature Test（HTTP）
│
├─ ■ バッチ／スケジュール
│   ├─ 実行方式：Artisan Command / Scheduler（Kernel.php）
│   ├─ 実行頻度：cron式
│   ├─ 処理仕様：べき等性あるか / トランザクション範囲
│   ├─ パフォーマンス：chunk処理 / メモリ上限
│   ├─ エラー処理：ログ出力 / 通知 / リトライ要否
│   └─ テスト：Unit Test / Integration Test
│
└─ ■ 非同期ジョブ（Queue）
    ├─ トリガー：Eventリスナー / 手動ディスパッチ
    ├─ キュー設定：queue名 / connection（Redis等）
    ├─ リトライ：回数 / バックオフ秒数
    ├─ 失敗処理：failed_jobs / Slack通知等
    └─ テスト：Unit Test（dispatchSync）
│
▼
【4. テスト方針】
├─ Feature Test（HTTPリクエスト〜レスポンス）
├─ Unit Test（単一クラス・メソッド）
└─ カバレッジ：正常系のみ？異常系・境界値まで？
│
▼
END
```

---

## ビジネスロジックの置き場所（共通判断）

| 複雑度 | 置き場所 |
|-------|---------|
| 単純 | Controller に直書き |
| 中程度 | FormRequest + Eloquent Model |
| 複雑 | Service クラスを切る |
| 横断的 | Action クラス（Single Responsibility） |

---

## 決定順序のポイント

「DB設計と認可を先に固める → 種別ごとの詳細 → テスト方針」の順で決めると手戻りが少ない。
