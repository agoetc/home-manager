{ config, pkgs, ... }:

{
  home.packages = [
    pkgs.fish
  ];

  programs.fish = {
    enable = true;
  };
}