---
name: notion-search
description: PREFIX-123 形式のIDがある場合に、Notion上の仕様・タスクを直接特定し、内容を取得する。
argument-hint: "[PREFIX-ID番号 or フィルタ条件]"
allowed-tools: Bash, mcp__memory__search_nodes, mcp__memory__create_entities, mcp__memory__add_observations
---

# Notion データベース検索

Notion 公式CLI `ntn` を使って Notion API を直接叩く。

`PREFIX-NUMBER` 形式の引数では、タイトル検索を行わず `unique_id` の直検索で対象ページを特定する。

## トークン設定

`NOTION_API_TOKEN` を sops で復号済みのパスから読み込んで export する。Bash ツールはコマンド間で shell state が保持されないため、`ntn` を呼ぶ bash 呼び出しの先頭で必ず export する。

```sh
export NOTION_API_TOKEN=$(cat /Users/takegawa/.config/sops-nix/secrets/notion_token)
```

以下の `ntn` 例はすべて、同一 bash コマンド内で上記 export 済みである前提。

## 引数のパース

`$ARGUMENTS` を以下のルールで判定する:

### 1. PREFIX-NUMBER 形式の場合（例: `XXX-1360`, `XXX-SUB-42`）

#### Step 1: Memory MCP からキャッシュ確認

`mcp__memory__search_nodes` で `query: "notion-ds-<PREFIX>"` を検索する。
（例: 引数が `FOO-123` なら `notion-ds-FOO` で検索）

**キャッシュがヒットした場合** → エンティティの observations から `data_source_id` と `unique_id_property` を取得し、Step 3 へ進む。

**キャッシュがなかった場合** → Step 2 へ。

#### Step 2: データベース検索 & キャッシュ保存

1. `ntn api '/v1/search' -X POST -d '{"filter":{"property":"object","value":"data_source"}}'` でデータソース一覧を取得
2. 各データソースの `properties` から `unique_id` 型のプロパティを探す
3. `unique_id.prefix` が引数のプレフィックス部分と一致するデータソースを特定
4. そのデータソースの `id` (= data_source_id) を取得
5. Memory MCP にキャッシュとして保存:

```
mcp__memory__create_entities:
  entities: [{
    name: "notion-ds-<PREFIX>",
    entityType: "notion-datasource",
    observations: [
      "data_source_id: <取得したID>",
      "unique_id_property: <プロパティ名>",
      "database_name: <DB名>"
    ]
  }]
```

#### Step 3: クエリ実行

```sh
ntn datasources query <data_source_id> \
  --filter '{"property":"<unique_idプロパティ名>","unique_id":{"equals":<数字部分>}}'
```

JSON で扱いたい場合は `--json` を付ける。

### 2. テキストの場合

タイトルで部分一致検索（対象データソースをユーザーに確認）:

```sh
ntn datasources query <data_source_id> \
  --filter '{"property":"Name","title":{"contains":"<テキスト>"}}'
```

### 3. ステータスキーワードの場合

| キーワード | ステータス値 |
|-----------|-------------|
| 未着手 | Not started |
| 進行中 / 作業中 | In progress |
| レビュー | Dev Review |
| QA / テスト | QA |
| リリース待ち | Release Waiting |
| リリース済み | Released |
| 完了 / クローズ | Closed |
| 保留 | Pending |

```sh
ntn datasources query <data_source_id> \
  --filter '{"property":"ステータス","status":{"equals":"<ステータス値>"}}'
```

## フィルタリファレンス

| 型 | フィルタ例 |
|---|---|
| title | `{"title": {"contains": "検索語"}}` |
| unique_id | `{"unique_id": {"equals": 809}}` |
| status | `{"status": {"equals": "In progress"}}` |
| select | `{"select": {"equals": "値"}}` |
| people | `{"people": {"contains": "user-uuid"}}` |
| date | `{"date": {"on_or_after": "2025-01-01"}}` |
| multi_select | `{"multi_select": {"contains": "値"}}` |

### 複合フィルタ

```sh
ntn datasources query <data_source_id> --filter '{
  "and": [
    { "property": "ステータス", "status": { "equals": "In progress" } },
    { "property": "区分", "select": { "equals": "開発要望" } }
  ]
}'
```

## ページ詳細取得

`ntn pages get <page-id>` で Markdown 形式の本文 + frontmatter プロパティを取得できる。

```sh
ntn pages get <page-id>            # Markdown 出力
ntn pages get <page-id> --json     # JSON 出力 (未対応ブロックの調査などに)
```

プロパティだけ詳細が欲しい場合は API を直叩き:

```sh
ntn api '/v1/pages/<page-id>'
```

## 出力フォーマット

検索結果は以下の形式で見やすくまとめること:

| 項目 | 値 |
|------|------|
| ID | PREFIX-番号 |
| タイトル | Name |
| ステータス | ステータス値 |
| アサイン | 担当者名 |
| リリース予定 | 日付 |
| URL | Notion URL |

ページの詳細な内容が必要な場合は `ntn pages get <page-id>` で本文を取得する。
