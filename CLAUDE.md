# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

macOS (aarch64-darwin) 用の Home Manager 設定リポジトリ。Nix Flakes で管理。

## Commands

```sh
# 設定を適用
nix flake update && home-manager switch

# フォーマット
trunk fmt

# Lint
trunk check
```

## Architecture

```
flake.nix              # エントリポイント。nixpkgs-unstable + nixpkgs-master を使用
home.nix               # メイン設定。importsのみ
programs/              # ツール別モジュール (各ディレクトリに default.nix + 関連ファイル)
  aws/                 # AWS CLI + SSM plugin
  claude/              # Claude Code設定 + CLAUDE.md, commands, skills, statusline.sh
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

## Conventions

- Nixファイルのフォーマット: `nixpkgs-fmt`
- シェルスクリプト: `shellcheck` + `shfmt`
