{ pkgs-master, ... }:

{
  home.file.".codex/AGENTS.md" = {
    source = ./AGENTS.md;
    force = true;
  };

  home.packages = [
    pkgs-master.codex
  ];
}
