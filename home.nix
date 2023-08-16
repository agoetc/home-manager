{ config, pkgs, ... }:

{
  # ユーザ情報
  home.username = "takegawa";
  home.homeDirectory = "/Users/takegawa";
  
  nixpkgs.config.allowUnfree = true;

  imports = [
    ./shell/zsh.nix
    # ./shell/fish.nix
  ];

  # 依存系
  home.stateVersion = "23.11";
  home.packages = [
    pkgs.git
    pkgs.gh
    pkgs.vscode
    pkgs.docker # 別途docker for macのインストールが必要
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}