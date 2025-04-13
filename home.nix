{ config, pkgs, ... }:

{
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
      mysql80
      online-judge-tools
      uv
    ];

  imports = [
    ./config/zsh.nix
    ./config/asdf.nix
    ./config/aws.nix
    ./config/nvim.nix
  ];
}
