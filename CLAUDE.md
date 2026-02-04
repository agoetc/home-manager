# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

macOS (aarch64-darwin) 用の Home Manager 設定リポジトリ。Nix Flakes で管理。

# IMPORTANT
- 全てnixで管理してください。
- 直接ファイルを編集しないでください。
- git add -A && nix flake update && home-manager switchで設定を適用してください。
- 新しいツールを追加する場合は programs/ 以下にモジュールを作成してください。
- モジュールを分けるまでもないものは、programs/packages/ にスタンドアロンパッケージとして追加してください。
- nixpkgs-unstable と nixpkgs-master を使用しています。最新パッケージが必要な場合は pkgs-master を使用してください。
- flake updateによってエラーが出る場合は、発生したパッケージを旧バージョンに固定してください。
- シークレットは sops-nix で管理。secrets.yaml に追加し `sops secrets.yaml` で編集。

## Commands

```sh
# 設定を適用
git add -A && nix flake update && home-manager switch

# シークレットの編集 (sops が自動で復号→編集→暗号化)
nix-shell -p sops --run "sops secrets.yaml"
```

## Architecture

```
flake.nix              # エントリポイント。nixpkgs-unstable + nixpkgs-master + sops-nix を使用
home.nix               # メイン設定。imports + sops secrets 定義
.sops.yaml             # sops 暗号化ルール (age 公開鍵)
secrets.yaml           # 暗号化済みシークレット (git コミット可能)
programs/              # ツール別モジュール (各ディレクトリに default.nix + 関連ファイル)
  aws/                 # AWS CLI + SSM plugin
  claude/              # Claude Code設定 + MCP servers (sops からトークン注入)
  codex/               # Codex + AGENTS.md
  git/                 # Git設定とghq roots
  gwq/                 # Git worktree manager (カスタムパッケージ含む)
  iterm2/              # iTerm2 Dynamic Profiles
  mise/                # ランタイムバージョン管理 (node, python, java, sbt等)
  nvim/                # Neovim (dracula theme)
  packages/            # スタンドアロンパッケージ一覧
  shogun/              # multi-agent-shogun (activation で自動clone)
  ssh/                 # SSH設定 (1Password agent)
  zsh/                 # シェル設定 (oh-my-zsh, starship, fzf, zoxide) + ghq-zsh.sh
```

### nixpkgs-master の使い方

最新パッケージが必要な場合は `pkgs-master` を使用:

```nix
# programs/*/default.nix 内で
pkgs-master.claude-code-bin
pkgs-master.k9s
```

### シークレット管理 (sops-nix)

age 鍵で暗号化。secrets.yaml は暗号化状態で git コミット可能。

```sh
# 鍵の場所: ~/Library/Application Support/sops/age/keys.txt
# 新しいシークレットを追加する場合:
# 1. home.nix の sops.secrets に定義を追加
# 2. sops secrets.yaml で値を編集
# 3. モジュール内で config.sops.secrets.<name>.path から読み取り
```

## Conventions

- Nixファイルのフォーマット: `nixpkgs-fmt`
- シェルスクリプト: `shellcheck` + `shfmt`
