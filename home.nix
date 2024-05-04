{ config, pkgs, ... }:

{
  settings.experimental-features = [ "nix-command" "flakes" ];

  programs.home-manager = {
    enable = true;
  };

  home = {
    username = "takegawa";
    homeDirectory = "/Users/takegawa";
    stateVersion = "23.11"; # Please read the comment before changing.
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
  ];
}
