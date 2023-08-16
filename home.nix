{ config, pkgs, ... }:

{
  home.username = "takegawa";
  home.homeDirectory = "/Users/takegawa";

  home.stateVersion = "23.11"; # Please read the comment before changing.

  home.packages = [
    pkgs.hello
    pkgs.starship
    pkgs.git   

    (pkgs.writeShellScriptBin "my-hello" ''
      echo "Hello, ${config.home.username}!"
    '')
  ];

  home.file = {
  };

  home.sessionVariables = {
    EDITOR = "vim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

}

