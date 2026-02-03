{ pkgs-master, ... }:

let
  claudeSettings = {
    "$schema" = "https://json.schemastore.org/claude-code-settings.json";
    enabledPlugins = {
      "context7@claude-plugins-official" = true;
      "swift-lsp@claude-plugins-official" = true;
      "document-skills@anthropic-agent-skills" = true;
    };
    permissions = {
      allow = [
        "Bash(rg *)"
        "Bash(fd *)"
        "Bash(eza *)"
        "Bash(jq *)"
        "Bash(mc *)"
      ];
    };
    alwaysThinkingEnabled = true;
    statusLine = {
      type = "command";
      command = "~/.claude/statusline.sh";
    };
  };

in
{
  home.file.".claude" = {
    source = ../files/claude;
    recursive = true;
    force = true;
  };

  home.file.".claude/settings.json" = {
    text = builtins.toJSON claudeSettings;
    force = true;
  };


  home.packages = [
    pkgs-master.claude-code-bin
  ];
}
