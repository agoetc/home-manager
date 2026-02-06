{ codex-pkg, ... }:

{
  home.file.".codex/AGENTS.md" = {
    source = ./AGENTS.md;
    force = true;
  };

  home.packages = [
    codex-pkg
  ];
}
