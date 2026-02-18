{ pkgs, ... }:

let
  multi-agent-shogun = pkgs.callPackage ./package.nix { };
in
{
  home.packages = [ multi-agent-shogun ];
}
