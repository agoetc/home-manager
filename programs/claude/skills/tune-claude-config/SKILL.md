---
name: tune-claude-config
description: 既存の Claude Code skill / slash command / subagent / hook の挙動を改善・観点追加・ルール追加する際に使用。ユーザーが「/<command>が甘かった」「<skill>が効かなかった」「次から<X>もチェックして」「<Y>の観点を足して」「<Z>のルールを追加して」等の振り返り・観点追加・ルール追加を依頼した時に発火。新規作成は add-claude-config を使う（こちらは既存定義の修正専用）。
---

# Tune Claude Config (既存定義の修正・観点追加)

既存の skill / command / agent / hook が「効かなかった」「観点が足りなかった」「ルールを追加したい」と判断されたとき、**ピンポイントに修正**するための skill。

新規作成は [[add-claude-config]] を使う。本 skill は **既存定義の改善** に特化。
反復評価が必要なときは [[empirical-prompt-tuning]] と組み合わせる（本 skill は単発の修正、後者は反復測定）。

## 発火する典型シグナル

| 発話例 | 意図 |
|---|---|
| 「`/review` が甘かった」「あのコマンド表面しか見てなかった」 | レビュー観点漏れの追加 |
| 「次から〜もチェックして」「〜の観点を足して」 | ルール・観点の追記 |
| 「`empirical-prompt-tuning` が誤発火する」 | 起動条件 (description) の修正 |
| 「コマンドの出力フォーマットを変えたい」 | 出力テンプレートの差し替え |
| 「あの skill のルールを厳しくして」 | 厳格度・トーンの調整 |

「**何が機能しなかったか**」を必ずユーザーから引き出すか、直近の対話履歴から特定する。

## 手順

### Step 1: 対象を特定する

ユーザーの発話から **どの skill / command を直すか** を確定。曖昧なら聞く。

```sh
# command 一覧
eza -la ~/.config/home-manager/programs/claude/commands/
# project-local commands も忘れずに
fd "\.md$" .claude/commands/ 2>/dev/null

# skill 一覧
eza -la ~/.config/home-manager/programs/claude/skills/

# agent 一覧
eza -la ~/.config/home-manager/programs/claude/agents/
```

プロジェクト固有版 (`<project>/.claude/commands/<name>.md`) と汎用版 (`~/.config/home-manager/programs/claude/commands/<name>.md`) の **両方が存在することがある**。両方更新するか片方かをユーザーに確認する。

### Step 2: 何が機能しなかったかを引き出す

ユーザーが具体的に言わない場合は **AskUserQuestion** で確認。例えば：

- 「指摘の網羅性が足りなかった？」「煽り口調が強すぎた？」「ドキュメントを読まなかった？」
- 「観点を追加したい？」「既存観点の表現を変えたい？」「出力フォーマットを変えたい？」

ヒアリングなしで全書き換えしない。**ピンポイント修正** が原則。

### Step 3: 既存ファイルを Read してから Edit

必ず `Read` で既読にした上で `Edit` を使う。`Write` で全書き換えはしない（既存の意図を壊す）。

| 操作 | ツール |
|---|---|
| セクション追記 (例: 「### 8. 新観点」) | `Edit` で `## 次のセクション` の前に挿入 |
| 既存項目の言い回し変更 | `Edit` で該当箇所のみ置換 |
| 出力テンプレート差し替え | `Edit` で `## 出力フォーマット` 全体を置換 |
| 全面書き直し（最終手段） | `Write` (ユーザーに「全書き換えでOK？」と確認後のみ) |

### Step 4: 配置先を必ず守る

`~/.claude/` は nix シンボリックリンク管理。直接編集しない。配置先マッピングは [[add-claude-config]] と共通。

| 種類 | 配置先 |
|---|---|
| user-level skill | `~/.config/home-manager/programs/claude/skills/<name>/SKILL.md` |
| user-level command | `~/.config/home-manager/programs/claude/commands/<name>.md` |
| user-level agent | `~/.config/home-manager/programs/claude/agents/<name>.md` |
| project command | `<project>/.claude/commands/<name>.md` (git管理対象) |
| project skill | `<project>/.claude/skills/<name>/SKILL.md` (git管理対象) |

### Step 5: 反映と確認

user-level の更新は `home-manager switch` で反映：

```sh
cd ~/.config/home-manager && git add -A && home-manager switch
# シンボリックリンクが /nix/store/... 向きになっているか確認
eza -la ~/.claude/skills/<name>/
eza -la ~/.claude/commands/
```

project-local の更新は switch 不要（ファイルがそのまま読まれる）。git commit はユーザー判断で。

## やってはいけないこと

- **対象を曖昧にしたまま全書き換え**: 「あのコマンド」だけで動かない。Step 1 で必ず確定
- **意図を確認せず観点を盛る**: 「観点を足して」と言われたとき、何が足りなかったかを聞かずに無関係な観点を追加しない
- **新規作成と修正を混同**: 既存ファイルがなければ [[add-claude-config]] にフォールバック
- **`~/.claude/` 直接編集**: nix activation で消える

## 改善のパターン例

### パターン A: レビュー観点の追加

```markdown
### N. <新観点名> (関連PRがあれば必須)
- <観点1の具体的チェック項目>
- <観点2の具体的チェック項目>
```

→ 既存の `### 7. テスト` の後に挿入。

### パターン B: 出力前セルフチェックの追加

```markdown
## 出力前チェック (必須・内部作業)
レビュー/出力する前に黙って自問する。ユーザーには見せない内部作業。

- [ ] <チェック項目1>
- [ ] <チェック項目2>

矛盾を見つけたら本体を修正してから出力。
```

→ `## 重要度` と `## 出力フォーマット` の間に挿入。

### パターン C: 起動条件 (description) の修正

skill の発火が広すぎる/狭すぎる場合、frontmatter の `description` を Edit。
**発火キーワードを description に明示** する（例: 「ユーザーが〜と言ったとき」）。

## 関連

- [[add-claude-config]] — 新規作成専用
- [[empirical-prompt-tuning]] — 反復評価で改善するワークフロー
