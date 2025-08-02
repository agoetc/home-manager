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
      pkgs-master.claude-code
      pkgs-master.k9s
    ];

  imports = [
    ./config/zsh.nix
    ./config/asdf.nix
    ./config/aws.nix
    ./config/nvim.nix
    ./config/git.nix
  ];
}
