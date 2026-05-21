---
name: notion-update
description: Notionページ・ブロックの更新・追記・新規作成。リッチブロック（heading/toggle/callout/code/divider）を活用して構造化された見やすい内容を書き込む。Markdownの平文貼り付けは禁止。
argument-hint: "[ページID or PREFIX-ID + 更新内容]"
allowed-tools: mcp__notion__API-patch-page, mcp__notion__API-update-a-block, mcp__notion__API-patch-block-children, mcp__notion__API-post-page, mcp__notion__API-delete-a-block, mcp__notion__API-retrieve-a-page, mcp__notion__API-get-block-children, mcp__notion__API-retrieve-a-block, mcp__notion__API-query-data-source, mcp__notion__API-post-search, mcp__notion__API-move-page, mcp__notion__API-create-a-comment, mcp__memory__search_nodes, Bash(curl:*)
---

# Notion ページ更新

## 大原則

**Markdown を平文として貼り付けない。** Notion はリッチブロックの集合体。`-` で全項目をフラットに並べると最悪の見た目になる。

## 書き込み前チェック

1. 対象ページIDを特定（PREFIX-ID 形式なら notion-search の手順でdata_source解決）
2. 既存ブロック構造を `API-get-block-children` で確認 → 既存トーンに合わせる
3. 追記か上書きか確認。**上書き時は対象ブロックIDを delete してから patch_children**

## ブロック選択ルール

| 内容 | ブロック型 |
|------|-----------|
| セクション見出し（大） | `heading_2` |
| セクション見出し（小） | `heading_3` |
| 補足・注意・結論 | `callout`（icon: 💡⚠️📝✅❌） |
| コマンド・コード・JSON・SQL | `code`（language 必須） |
| 折りたためる長い詳細 | `toggle` |
| 短い箇条書き（1行=1事実） | `bulleted_list_item` |
| 順序のある手順 | `numbered_list_item` |
| セクション境界 | `divider` |
| 表形式データ | `table` |
| 引用・参考 | `quote` |

## 進捗報告・調査メモのテンプレ

**悪い例**（フラット bullet で長文段落を並列）:
```
- 現状の K8s 採点経路には Job 投入数の hard cap が無く、5min 3000件流入時に最大 3000 Pod が同時 active 化するリスクを特定。Worker は SQS メッセージを Job 投入直後に即削除する設計で、SQS 側にバックプレッシャが効かない。
- 対策として Kueue 導入を決定。...
```

**良い構造**:

```
heading_2: 📝 進捗 (2026-04-27): Rate Limiting 調査 + Kueue 導入設計
divider
callout(💡 TL;DR): 1-2行サマリ
heading_3: 🔍 課題
  bulleted_list_item: 短文1行（数値・識別子は code で強調）
  bulleted_list_item: ...
heading_3: 🎯 対策
  bulleted_list_item: ...
heading_3: 📐 キャパシティ設計
  table または bulleted_list_item
heading_3: 🛡️ 安全装置
  bulleted_list_item: ...
heading_3: 📊 モニタリング
  bulleted_list_item: ...
heading_3: 🚀 段階導入計画
  numbered_list_item: Phase 0 - ...
  numbered_list_item: Phase 1 - ...
heading_3: 📦 成果物
  bulleted_list_item: doc + branch + commit を code で
heading_3: ❓ オープンアイテム
  to_do: 未解決項目
toggle: 🔧 詳細補足（必要時のみ展開）
```

## インライン装飾

rich_text 配列で `annotations` を使う:

| 対象 | 装飾 |
|------|------|
| ファイルパス・関数名・変数名・コマンド | `code: true` |
| キーワード・重要数値 | `bold: true` |
| プロパティ名・用語 | `italic: true` |
| URL・PR・Commit hash | `link.url` |

**例**:
```json
{
  "type": "bulleted_list_item",
  "bulleted_list_item": {
    "rich_text": [
      {"type": "text", "text": {"content": "並列上限 "}},
      {"type": "text", "text": {"content": "max_node=200"}, "annotations": {"code": true}},
      {"type": "text", "text": {"content": " で "}},
      {"type": "text", "text": {"content": "600 Pod"}, "annotations": {"bold": true}},
      {"type": "text", "text": {"content": " を吸収"}}
    ]
  }
}
```

## 1 bullet = 1 fact

**禁止**: 「〜を特定。〜は〜で〜が効かない。」のように1 bullet に複数センテンス。

**正**:
- 1文目を bullet 本体に
- 補足・理由は **子ブロック**（indent）または `toggle` に格納
- それでも長くなる場合は `heading_3` でセクション分割

## 文字数ガイド

| ブロック | 推奨 | 上限 |
|---------|------|------|
| heading_2/3 | 〜30字 | 50字 |
| bulleted_list_item | 〜40字 | 80字 |
| callout | 〜80字 | 200字 |
| paragraph | - | 段落分割推奨 |

超える場合は分割。

## コード・コマンドの扱い

inline code（`code: true` annotation）と code block を使い分ける:

- 短い識別子・1行コマンド → inline `code`
- 複数行・JSON・YAML・SQL → `code` block（language 指定）

```json
{
  "type": "code",
  "code": {
    "rich_text": [{"type": "text", "text": {"content": "..."}}],
    "language": "yaml"
  }
}
```

## テーブル

### 使うべき場面

- **2列以上で項目間の対応関係を示す**（パラメータ vs 値、環境別設定、比較）
- **同じ属性を持つ複数エンティティの一覧**（Phase/期間/担当、quota設定、メトリクス閾値）
- 3行未満なら bullet で十分。**3行以上 & 2列以上**が table の目安

### 使うべきでない場面

- 単一カラムの羅列 → `bulleted_list_item`
- セル内に長文・複数センテンス → `bulleted_list_item` + 子ブロック
- 階層構造を持つデータ → `toggle` のネスト

### 構造ルール

```json
{
  "type": "table",
  "table": {
    "table_width": 3,
    "has_column_header": true,
    "has_row_header": false,
    "children": [
      {
        "type": "table_row",
        "table_row": {
          "cells": [
            [{"type": "text", "text": {"content": "環境"}, "annotations": {"bold": true}}],
            [{"type": "text", "text": {"content": "max_node"}, "annotations": {"bold": true, "code": true}}],
            [{"type": "text", "text": {"content": "用途"}, "annotations": {"bold": true}}]
          ]
        }
      },
      {
        "type": "table_row",
        "table_row": {
          "cells": [
            [{"type": "text", "text": {"content": "staging"}}],
            [{"type": "text", "text": {"content": "10"}, "annotations": {"code": true}}],
            [{"type": "text", "text": {"content": "dark launch"}}]
          ]
        }
      }
    ]
  }
}
```

### 必須事項

- `table_width` = 列数。**全 `table_row` の `cells` 配列長が一致必須**（不一致は API エラー）
- 各セルは **rich_text 配列**（文字列ではない）。空セルも `[]` ではなく `[{"type": "text", "text": {"content": ""}}]` が安全
- `has_column_header: true` の場合、**1行目をヘッダー扱い**にして bold 装飾を入れる
- `has_row_header: true` は左端列見出し用。環境別/Phase別の比較表で有効
- `children` は **table_row のみ**。table_row 内に他ブロックはネスト不可

### 推奨設計

| 観点 | 推奨 |
|------|------|
| 列数 | 2〜5列。6列超は visual に潰れる → 縦持ちか分割 |
| セル文字数 | 〜20字。長文は本文 bullet に切り出す |
| 数値・識別子 | `code` annotation で強調 |
| 見出し列 | `bold` annotation |
| 整列 | Notion はセル内整列指定不可 — 数値もそのまま左寄せ |

### よくある失敗

- **markdown table をそのまま rich_text に貼る** → ただの `|` 記号の文字列として表示
- **cells 配列の長さ不一致** → API がブロック全体を拒否
- **セル内に code block を入れようとする** → table_row は rich_text のみ受け付ける。`code` annotation で代替

### 進捗メモでの活用例

キャパシティ設計、quota割当、Phase スケジュール、メトリクス閾値は table 化で激変:

```
heading_3: 📐 キャパシティ設計
table (table_width=4, has_column_header=true):
  ヘッダー: 環境 | max_node | 並列上限 | 用途
  staging  | 10  | 30   | dark launch
  prod CPU | 200 | 600  | 通常採点
  prod GPU | 5   | 15   | 推論採点
```

## 段階的・複数フェーズ計画

`numbered_list_item` + 子ブロックで階層化、または `toggle` で各 Phase を畳む:

```
toggle: Phase 1 - infra (Kueue install + node pool 追加)
  bulleted_list_item: 詳細1
  bulleted_list_item: 詳細2
  code: terraform diff
```

## オープンアイテム

`to_do` ブロック使用。チェック可能で残作業が一目でわかる:

```json
{"type": "to_do", "to_do": {"rich_text": [...], "checked": false}}
```

## 更新フロー

1. `API-retrieve-a-page` でページ存在・親確認
2. `API-get-block-children` で既存構造把握
3. 追記位置決定（末尾 or 特定ブロック直後 = `after` 引数）
4. 上記ルールでブロック配列を組み立て
5. `API-patch-block-children` で投入
6. 投入後、`API-get-block-children` で結果確認

## MCP制約と API 直叩き代替

MCP server (@notionhq/notion-mcp-server) は Notion API のサブセット。以下は **MCP不可だが API直叩きで可能**。

### トークン参照

sops-nix で復号済み:

```sh
TOKEN=$(cat ~/.config/sops-nix/secrets/notion_token)
NV="2025-09-03"
```

### MCP不可・API可能な操作

| 操作 | エンドポイント | 用途 |
|------|---------------|------|
| File Upload | `POST /v1/file_uploads` + `PATCH/PUT` | 画像/PDF/動画を Notion 内ホスト |
| Comment 更新 | `PATCH /v1/comments/{id}` | 自分のコメント編集 |
| Comment 削除 | `DELETE /v1/comments/{id}` | 自分のコメント削除 |
| Block単位コメント | `POST /v1/comments` w/ `parent.block_id` | 特定ブロックへのコメント |
| OAuth token 管理 | `POST /v1/oauth/token`, `revoke`, `refresh-token` | integration token操作 |
| Database (legacy) 作成 | `POST /v1/databases` | 旧API DB作成 |
| View 管理 | `/v1/databases/{id}/views` | 公開ビュー作成・編集 |

### curl テンプレ

```sh
TOKEN=$(cat ~/.config/sops-nix/secrets/notion_token)

# 共通 GET
curl -s -H "Authorization: Bearer $TOKEN" \
     -H "Notion-Version: 2025-09-03" \
     "https://api.notion.com/v1/<path>"

# 共通 POST/PATCH
curl -s -X POST \
     -H "Authorization: Bearer $TOKEN" \
     -H "Notion-Version: 2025-09-03" \
     -H "Content-Type: application/json" \
     -d '{...}' \
     "https://api.notion.com/v1/<path>"
```

### File Upload 完全手順

```sh
TOKEN=$(cat ~/.config/sops-nix/secrets/notion_token)

# 1. アップロード作成（< 20MB は single_part）
RESP=$(curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Notion-Version: 2025-09-03" \
  -H "Content-Type: application/json" \
  -d '{"mode": "single_part", "filename": "image.png", "content_type": "image/png"}' \
  https://api.notion.com/v1/file_uploads)

UPLOAD_ID=$(echo "$RESP" | jq -r '.id')
UPLOAD_URL=$(echo "$RESP" | jq -r '.upload_url')

# 2. ファイル送信
curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Notion-Version: 2025-09-03" \
  -F "file=@image.png" \
  "$UPLOAD_URL"

# 3. ブロックに添付（mcp__notion__API-patch-block-children でも可）
curl -s -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  -H "Notion-Version: 2025-09-03" \
  -H "Content-Type: application/json" \
  -d "{\"children\": [{\"type\": \"image\", \"image\": {\"type\": \"file_upload\", \"file_upload\": {\"id\": \"$UPLOAD_ID\"}}}]}" \
  "https://api.notion.com/v1/blocks/<page_or_block_id>/children"
```

### Comment 削除

```sh
TOKEN=$(cat ~/.config/sops-nix/secrets/notion_token)
curl -s -X DELETE \
  -H "Authorization: Bearer $TOKEN" \
  -H "Notion-Version: 2025-09-03" \
  "https://api.notion.com/v1/comments/<comment_id>"
```

### Block単位コメント作成

```sh
TOKEN=$(cat ~/.config/sops-nix/secrets/notion_token)
curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Notion-Version: 2025-09-03" \
  -H "Content-Type: application/json" \
  -d '{
    "parent": {"block_id": "<block_id>"},
    "rich_text": [{"type": "text", "text": {"content": "コメント本文"}}]
  }' \
  https://api.notion.com/v1/comments
```

### API でも不可（Notion本体制約）

| 操作 | 代替 |
|------|------|
| Block type 変換（heading→toggle 等） | `delete-a-block` + `patch-block-children` で再作成 |
| 物理削除 | `archived: true` / `in_trash: true` のみ。完全削除は人手 |
| Webhook subscription API登録 | Notion管理画面UIから登録のみ |

### 使い分け判断

1. **MCP ツールが存在する操作** → MCP優先（型安全・引数検証）
2. **MCP不可・上表に該当** → curl で API直叩き
3. **トークン漏洩防止** — curl コマンドにトークンをベタ書きせず、必ず `$(cat ~/.config/sops-nix/secrets/notion_token)` で展開

## 禁止事項

- markdown 記法（`#`, `-`, `**`, `` ` ``）を text content にそのまま入れる
- 1 bullet に 100字超の段落
- code/identifier をプレーンテキストのまま
- セクション境界なしの連続 bullet（10件超）
- emoji なしの単調なリスト（視認性低下）
- **トークンをコマンドラインにベタ書き**（必ず `$(cat ~/.config/sops-nix/secrets/notion_token)` 経由）
- **API 直叩きで MCP ツール存在する操作を行う**（MCP優先）
