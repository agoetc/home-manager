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
flake.nix           # エントリポイント。nixpkgs-unstable + nixpkgs-master を使用
home.nix            # メイン設定。パッケージ一覧とモジュールimports
config/             # 機能別モジュール
  zsh.nix           # シェル設定 (oh-my-zsh, p10k, fzf, zoxide)
  mise.nix          # ランタイムバージョン管理 (node, python, java, sbt等)
  git.nix           # Git設定とghq roots
  nvim.nix          # Neovim (dracula theme)
  claude.nix        # Claude Code設定 (files/claudeをホームに配置)
  aws.nix           # AWS CLI + SSM plugin
  iterm2.nix        # iTerm2 Dynamic Profiles
shell/              # zshから読み込むスクリプト
files/claude/       # ~/.claudeに配置されるファイル群
```

### nixpkgs-master の使い方

最新パッケージが必要な場合は `pkgs-master` を使用:

```nix
# home.nix または各config内で
pkgs-master.claude-code
pkgs-master.k9s
```

## Conventions

- Nixファイルのフォーマット: `nixpkgs-fmt`
- シェルスクリプト: `shellcheck` + `shfmt`
