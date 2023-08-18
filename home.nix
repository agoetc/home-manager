{ config, pkgs, ... }:

{  
  imports = [
    ./shell/zsh.nix
    # ./shell/fish.nix
  ];

  # 依存系
  home.packages = with pkgs; [
    git
    gh
    vscode
    jq

    awscli
  ];
  
  # ユーザ情報
  home.username = "takegawa";
  home.homeDirectory = "/Users/takegawa";

  nixpkgs.config = {
    allowUnfree = true;
  };

  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
