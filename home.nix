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
    ./config/claude.nix
    ./config/iterm2.nix
    ./config/ssh.nix
  ];
}
