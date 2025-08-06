{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    ignores = [
      ".serena"
      ".idea"
      ".vscode"
      ".claude/settings.local.json"
    ];
    aliases = {
      # merge済みブランチを削除
      cleanup = "!git branch --merged | grep -v '\\*\\|main\\|master\\|develop' | xargs -n 1 git branch -d";
      # リモートで削除されたブランチのローカル追跡ブランチを削除
      prune-local = "!git remote prune origin && git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -n 1 git branch -D";
      # 両方を実行
      cleanup-all = "!git cleanup && git prune-local";
    };
  };
}