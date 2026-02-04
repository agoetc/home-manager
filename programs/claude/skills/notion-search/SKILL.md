---
name: notion-search
description: Notionのデータベースを検索する。PREFIX-123 形式のIDやステータス、テキストで絞り込みが可能。
argument-hint: "[PREFIX-ID番号 or フィルタ条件]"
allowed-tools: mcp__notion__API-query-data-source, mcp__notion__API-retrieve-a-page, mcp__notion__API-get-block-children, mcp__notion__API-post-search, mcp__memory__search_nodes, mcp__memory__create_entities, mcp__memory__add_observations
---

# Notion データベース検索

## 引数のパース

`$ARGUMENTS` を以下のルールで判定する:

### 1. PREFIX-NUMBER 形式の場合（例: `XXX-1360`, `XXX-SUB-42`）

#### Step 1: Memory MCP からキャッシュ確認

`mcp__memory__search_nodes` で `query: "notion-ds-<PREFIX>"` を検索する。
（例: 引数が `FOO-123` なら `notion-ds-FOO` で検索）

**キャッシュがヒットした場合** → エンティティの observations から `data_source_id` と `unique_id_property` を取得し、Step 3 へ進む。

**キャッシュがなかった場合** → Step 2 へ。

#### Step 2: データベース検索 & キャッシュ保存

1. `mcp__notion__API-post-search` で `filter: {property: "object", value: "data_source"}` を使いデータベース一覧を取得
2. 各データベースの `properties` から `unique_id` 型のプロパティを探す
3. `unique_id.prefix` が引数のプレフィックス部分と一致するデータベースを特定
4. リレーションプロパティの `relation.data_source_id` から data_source_id を取得
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

```json
{
  "data_source_id": "<取得したdata_source_id>",
  "filter": {
    "property": "<unique_idプロパティ名>",
    "unique_id": { "equals": <数字部分> }
  }
}
```

### 2. テキストの場合

タイトルで部分一致検索（対象データベースをユーザーに確認）:

```json
{
  "filter": {
    "property": "Name",
    "title": { "contains": "<テキスト>" }
  }
}
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

```json
{
  "filter": {
    "property": "ステータス",
    "status": { "equals": "<ステータス値>" }
  }
}
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

```json
{
  "filter": {
    "and": [
      { "property": "ステータス", "status": { "equals": "In progress" } },
      { "property": "区分", "select": { "equals": "開発要望" } }
    ]
  }
}
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

ページの詳細な内容が必要な場合は `API-get-block-children` で本文を取得する。
