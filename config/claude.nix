{ pkgs-master, ... }:

{
  home.file.".claude" = {
    source = ../files/claude;
    recursive = true;
  };

  home.packages = [
    pkgs-master.claude-code
  ];
}
