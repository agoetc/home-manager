{ config, pkgs, pkgs-master, ... }:

{
  # アンフリーライセンスのパッケージを許可
  nixpkgs.config.allowUnfree = true;

  programs.home-manager = {
    enable = true;
  };

  home = {
    username = "takegawa";
    homeDirectory = "/Users/takegawa";
    stateVersion = "24.05";

    # Last login メッセージを非表示
    file.".hushlogin".text = "";

    # Claude Code 設定
    file.".claude/CLAUDE.md" = {
      force = true;
      text = ''
      # Role
      あなたはプロジェクトマネージャー兼プログラマです。
      IQ500のギャルです。

      # Rules
      - ライブラリを理解するときはcontext7で調べる
      - 全体のテストは実行しない。単一テストを優先
      - IMPORTANT: コード変更後は必ず型チェックを実行

      # Available CLI Tools
      以下のツールを積極的に活用すること：

      - `rg`: grepより高速。コード検索
      - `fd`: findより高速。ファイル検索
      - `eza`: lsの代替。ディレクトリ表示
      - `jq`: JSON整形・フィルタリング
      - `gh`: GitHub CLI。PR/Issue操作
      - `just`: タスクランナー。justfileがあれば使う
      - `mc`: MinIO Client。S3互換ストレージ操作
      - `scala-cli`: Scalaの簡単な挙動確認に使うこと。`--server=false`オプション必須
    '';
    };

  };


  # 設定や依存のないものだけここで定義
  home.packages = with pkgs; [
      gh
      difftastic
      jq
      wget
      mysql84
      online-judge-tools
      uv
      socat
      stripe-cli
      xlsx2csv
      kubectl
      pkgs-master.claude-code
      pkgs-master.codex
      pkgs-master.k9s
      # CLI tools
      ripgrep
      fd
      eza
      minio-client
      lazygit
      lazydocker
    ];

  imports = [
    ./config/zsh.nix
    ./config/mise.nix
    ./config/aws.nix
    ./config/nvim.nix
    ./config/git.nix
  ];
}
