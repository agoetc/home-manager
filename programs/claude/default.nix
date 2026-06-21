{ claude-code-pkg, pkgs, lib, config, ... }:

let
  claudeSettings = {
    "$schema" = "https://json.schemastore.org/claude-code-settings.json";
    enabledPlugins = {
      "context7@claude-plugins-official" = true;
      "swift-lsp@claude-plugins-official" = true;
      "document-skills@anthropic-agent-skills" = true;
      "codex@openai-codex" = true;
      "superpowers@superpowers-marketplace" = true;
      "elements-of-style@superpowers-marketplace" = true;
      "superpowers-developing-for-claude-code@superpowers-marketplace" = true;
      "private-journal-mcp@superpowers-marketplace" = true;
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
    # alwaysThinkingEnabled は runtime トグル (/thinking 等) なので宣言しない。
    # model / effortLevel も同様に runtime 所有とし、ここでは宣言しない。
    skipDangerousModePermissionPrompt = true;
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
    # headroom: コンテキスト圧縮 MCP (compress/retrieve/stats)。
    # バイナリは mise の pipx:headroom-ai 経由で PATH に入る。
    headroom = {
      type = "stdio";
      command = "headroom";
      args = [ "mcp" "serve" ];
      env = { };
    };
  };

in
{
  home.file.".claude" = {
    source = ./.;
    recursive = true;
    force = true;
  };

  # Write settings.json as a regular writable file (not a Nix store symlink)
  # so that Claude Code runtime commands like /effort and /model can modify it.
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SETTINGS_FILE="$HOME/.claude/settings.json"
    SETTINGS_JSON='${builtins.toJSON claudeSettings}'

    mkdir -p "$HOME/.claude"
    # Preserve any runtime-added keys (e.g. model, effortLevel) by merging
    if [ -f "$SETTINGS_FILE" ] && [ ! -L "$SETTINGS_FILE" ]; then
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$SETTINGS_FILE" - <<< "$SETTINGS_JSON" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    else
      # Remove symlink if present, then write fresh
      rm -f "$SETTINGS_FILE"
      echo "$SETTINGS_JSON" | ${pkgs.jq}/bin/jq '.' > "$SETTINGS_FILE"
    fi
  '';

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

  # Register plugin marketplaces and install plugins declaratively
  home.activation.claudePlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    PLUGINS_DIR="$HOME/.claude/plugins"
    KNOWN="$PLUGINS_DIR/known_marketplaces.json"
    INSTALLED="$PLUGINS_DIR/installed_plugins.json"

    mkdir -p "$PLUGINS_DIR"

    # --- Marketplace registration via CLI ---
    # `claude plugin marketplace add` clones the repo and populates the
    # installLocation/lastUpdated fields Claude's schema requires. Hand-writing
    # known_marketplaces.json yields incomplete entries that Claude rejects as
    # "corrupted", so registration MUST go through the CLI.
    register_marketplace() {
      local mp_name="$1" mp_repo="$2"
      if [ -f "$KNOWN" ] && ${pkgs.jq}/bin/jq -e --arg m "$mp_name" '.[$m].installLocation' "$KNOWN" > /dev/null 2>&1; then
        return 0
      fi
      echo "Adding Claude marketplace: $mp_name ($mp_repo)"
      claude plugin marketplace add "$mp_repo" 2>/dev/null || true
    }

    register_marketplace "openai-codex" "openai/codex-plugin-cc"
    register_marketplace "superpowers-marketplace" "obra/superpowers-marketplace"

    # --- Plugin installation via CLI ---
    # Only install if not already in installed_plugins.json
    install_plugin() {
      local plugin_id="$1"
      if [ -f "$INSTALLED" ] && ${pkgs.jq}/bin/jq -e --arg p "$plugin_id" '.plugins[$p]' "$INSTALLED" > /dev/null 2>&1; then
        return 0
      fi
      echo "Installing Claude plugin: $plugin_id"
      claude plugin install "$plugin_id" 2>/dev/null || true
    }

    install_plugin "codex@openai-codex"
    install_plugin "superpowers@superpowers-marketplace"
    install_plugin "elements-of-style@superpowers-marketplace"
    install_plugin "superpowers-developing-for-claude-code@superpowers-marketplace"
    install_plugin "private-journal-mcp@superpowers-marketplace"
  '';

  home.sessionVariables = {
    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
  };

  home.packages = [
    claude-code-pkg
  ];
}
