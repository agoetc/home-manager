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
      pkgs-master.claude-code
      pkgs-master.codex
      pkgs-master.k9s
    ];

  imports = [
    ./config/zsh.nix
    ./config/mise.nix
    ./config/aws.nix
    ./config/nvim.nix
    ./config/git.nix
  ];
}
