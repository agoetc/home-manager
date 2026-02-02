{ pkgs-master, pkgs, ... }:

let
  claudeSettings = {
    "$schema" = "https://json.schemastore.org/claude-code-settings.json";
    enabledPlugins = {
      "serena@claude-plugins-official" = true;
      "context7@claude-plugins-official" = true;
      "swift-lsp@claude-plugins-official" = true;
      "Notion@claude-plugins-official" = true;
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

  # ~/.claude.json にマージするMCPサーバー定義
  mcpServers = {
    grepai = {
      type = "stdio";
      command = "grepai";
      args = [ "mcp-serve" ];
    };
  };

  mcpServersJson = builtins.toJSON mcpServers;
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

  # home-manager switch 時に ~/.claude.json の mcpServers をマージ
  home.activation.claudeMcpServers = ''
    CLAUDE_JSON="$HOME/.claude.json"
    if [ ! -f "$CLAUDE_JSON" ]; then
      echo "claude.json not found, skipping MCP server setup"
      exit 0
    fi
    ${pkgs.jq}/bin/jq --argjson servers '${mcpServersJson}' \
      '.mcpServers = (.mcpServers // {}) * $servers' \
      "$CLAUDE_JSON" > "$CLAUDE_JSON.tmp" && mv "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
  '';

  home.packages = [
    pkgs-master.claude-code
  ];
}
