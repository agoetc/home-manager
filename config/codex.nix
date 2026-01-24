{ pkgs-master, ... }:

{
  home.file.".codex/AGENTS.md" = {
    source = ../files/codex/AGENTS.md;
    force = true;
  };

  home.packages = [
    pkgs-master.codex
  ];
}
