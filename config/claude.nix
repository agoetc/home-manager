{ pkgs-master, ... }:

{
  home.file = {
    ".claude/CLAUDE.md".source = ../files/claude/CLAUDE.md;
    ".claude/commands/review.md".source = ../files/claude/commands/review.md;
  };

  home.packages = [
    pkgs-master.claude-code
  ];
}
