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
      online-judge-tools
    ];

  imports = [
    ./config/zsh.nix
    ./config/asdf.nix
    ./config/aws.nix
  ];
}
