{ claude-code-pkg, pkgs, lib, config, ... }:

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

  # MCP servers without secrets
  mcpServers = {
    memory = {
      command = "npx";
      args = [ "-y" "@modelcontextprotocol/server-memory" ];
    };
    sequential-thinking = {
      command = "npx";
      args = [ "-y" "@modelcontextprotocol/server-sequential-thinking" ];
    };
  };

in
{
  home.file.".claude" = {
    source = ./.;
    recursive = true;
    force = true;
  };

  home.file.".claude/settings.json" = {
    text = builtins.toJSON claudeSettings;
    force = true;
  };

  # MCP servers are stored in ~/.claude.json (user config)
  # Use jq to merge without destroying runtime state
  # Runs after sops secrets are decrypted (setupSopsSecrets)
  home.activation.claudeMcpServers = lib.hm.dag.entryAfter [ "sops-nix" ] ''
    CLAUDE_JSON="$HOME/.claude.json"
    MCP_SERVERS='${builtins.toJSON mcpServers}'
    NOTION_SECRET="${config.sops.secrets.notion_token.path}"

    # Add notion MCP if secret file exists and is non-empty
    if [ -f "$NOTION_SECRET" ] && [ -s "$NOTION_SECRET" ]; then
      NOTION_TOKEN=$(cat "$NOTION_SECRET")
      NOTION_HEADERS="{\"Authorization\": \"Bearer $NOTION_TOKEN\", \"Notion-Version\": \"2025-09-03\"}"
      MCP_SERVERS=$(echo "$MCP_SERVERS" | ${pkgs.jq}/bin/jq \
        --arg headers "$NOTION_HEADERS" \
        '. + {notion: {command: "npx", args: ["-y", "@notionhq/notion-mcp-server"], env: {OPENAPI_MCP_HEADERS: $headers}}}')
    else
      echo "WARNING: notion_token secret is empty. Skipping notion MCP server." >&2
    fi

    # Merge local MCP servers (not managed by home-manager)
    LOCAL_MCP="$HOME/.claude/local-mcp-servers.json"
    if [ -f "$LOCAL_MCP" ]; then
      MCP_SERVERS=$(echo "$MCP_SERVERS" | ${pkgs.jq}/bin/jq --slurpfile local "$LOCAL_MCP" '. + $local[0]')
    fi

    if [ -f "$CLAUDE_JSON" ]; then
      ${pkgs.jq}/bin/jq --argjson servers "$MCP_SERVERS" '.mcpServers = $servers' "$CLAUDE_JSON" > "$CLAUDE_JSON.tmp" && mv "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
    else
      echo '{}' | ${pkgs.jq}/bin/jq --argjson servers "$MCP_SERVERS" '.mcpServers = $servers' > "$CLAUDE_JSON"
    fi
  '';

  home.sessionVariables = {
    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "0";
  };

  home.packages = [
    claude-code-pkg
  ];
}
