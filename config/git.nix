{ config, pkgs, ... }:

let
  signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB4dt6xMFVi5EFaVVokz2D8LYqV3K9QztXhpBJDd4l9e";
  email = "tkgw666private@gmail.com";
in
{
  # allowed_signers ファイルを作成
  home.file.".ssh/allowed_signers".text = ''
    ${email} ${signingKey}
  '';

  programs.git = {
    enable = true;
    signing = {
      key = signingKey;
      signByDefault = true;
    };
    ignores = [
      ".serena"
      ".idea"
      ".vscode"
      ".claude/settings.local.json"
      "tsconfig.tsbuildinfo"
      ".DS_Store"
    ];
    settings = {
      user = {
        name = "agoetc";
        email = email;
      };
      gpg = {
        format = "ssh";
        ssh = {
          program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
          allowedSignersFile = "~/.ssh/allowed_signers";
        };
      };
      ghq = {
        root = [
          "~/Work"
          "~/.config"
        ];
      };
      alias = {
        # merge済みブランチを削除
        cleanup = "!git branch --merged | grep -v '\\*\\|main\\|master\\|develop' | xargs -n 1 git branch -d";
        # リモートで削除されたブランチのローカル追跡ブランチを削除
        prune-local = "!git remote prune origin && git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -n 1 git branch -D";
        # 両方を実行
        cleanup-all = "!git cleanup && git prune-local";
        ca = "!git cleanup-all";
        # 人間用（difftastic使う）
        difft = "difftool --no-prompt --extcmd='difft'";
        d = "!git difft";
        # 現在のブランチをブラウザで開く
        browse = "!gh browse -b $(git branch --show-current)";
        b = "!git browse";
      };
    };
  };
}