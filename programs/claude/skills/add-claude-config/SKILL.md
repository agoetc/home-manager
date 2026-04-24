---
name: add-claude-config
description: Claude Code の skill / slash command / subagent / hook / 設定を追加・変更する際に使用。~/.claude/ はnix管理されているため、直接編集せず ~/.config/home-manager/programs/claude/ 配下に配置して home-manager switch で反映する。ユーザーが「skillを追加して」「slash commandを作って」「Claude Codeの設定を変えて」等と依頼した時に発火。
---

# Add Claude Config (nix-managed)

`~/.claude/` 配下は home-manager でシンボリックリンク管理されている。直接編集してもnix活性化時に上書きされる、もしくはgit管理外になる。必ず `~/.config/home-manager/programs/claude/` 配下に配置して home-manager switch で反映する。

## 配置先マッピング

| 種類 | 配置先 | 配置後のリンク先 |
|---|---|---|
| skill | `~/.config/home-manager/programs/claude/skills/<name>/SKILL.md` | `~/.claude/skills/<name>/SKILL.md` |
| slash command | `~/.config/home-manager/programs/claude/commands/<name>.md` | `~/.claude/commands/<name>.md` |
| subagent | `~/.config/home-manager/programs/claude/agents/<name>.md` | `~/.claude/agents/<name>.md` |
| settings.json | `~/.config/home-manager/programs/claude/default.nix` の `claudeSettings` を編集 | `~/.claude/settings.json` |
| MCP server | `~/.config/home-manager/programs/claude/default.nix` の `mcpServers` を編集 | `~/.claude.json` |
| statusline | `~/.config/home-manager/programs/claude/statusline.sh` を編集 | `~/.claude/statusline.sh` |
| CLAUDE.md (global) | `~/.config/home-manager/programs/claude/CLAUDE.md` を編集 | `~/.claude/CLAUDE.md` |

skill / command / agent は `home.file.".claude".source = ./.; recursive = true;` により `programs/claude/` 配下全体が自動的にシンボリックリンクされる。ディレクトリを追加するだけで済む。

## 手順

1. 対象ファイルを上記マッピングの配置先に作成・編集する
2. `cd ~/.config/home-manager && git add -A && home-manager switch` で反映
3. `~/.claude/<target>` がシンボリックリンクになっているか確認（`eza -la` で `/nix/store/...` 向きになっていれば成功）

## やってはいけないこと

- `~/.claude/skills/` `~/.claude/commands/` `~/.claude/agents/` などに直接ファイルを作成する（nix管理外）
- `~/.claude/settings.json` `~/.claude/CLAUDE.md` を直接編集する（次回switch時に上書きされる）
- `home.file` 定義を迂回してファイル作成する

## 例外

- `~/.claude.json` の runtime state（プロジェクトごとの履歴等）: home-manager の activation script が jq でマージするため、ユーザー操作での直接編集は不要
- `~/.claude/local-mcp-servers.json`: ローカル専用MCP。nix管理対象外として意図的に分離されているため直接編集可

## 確認コマンド

```sh
# skill / command / agent がリンクされているか
eza -la ~/.claude/skills/<name>/
eza -la ~/.claude/commands/
eza -la ~/.claude/agents/

# settings が反映されているか
jq . ~/.claude/settings.json
```
