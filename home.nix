{ config, pkgs, ... }:

{
  home = {
    username = "takegawa";
    homeDirectory = "/Users/takegawa";
    stateVersion = "23.11"; # Please read the comment before changing.
  };


  home.packages = with pkgs; [
      gh
      difftastic
      jq
      online-judge-tools
    ];

  imports = [
    ./config/zsh.nix
  ];
}
