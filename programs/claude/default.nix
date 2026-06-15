{ claude-code-pkg, pkgs, lib, config, ... }:

let
  claudeSettings = {
    "$schema" = "https://json.schemastore.org/claude-code-settings.json";
    enabledPlugins = {
      "context7@claude-plugins-official" = true;
      "swift-lsp@claude-plugins-official" = true;
      "document-skills@anthropic-agent-skills" = true;
      "codex@openai-codex" = true;
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
    # Opus 4.6 を /model ピッカーに追加。標準 Anthropic API では availableModels は
    # 制限(allowlist)でありモデル追加はできないため、公式の追加手段である
    # ANTHROPIC_CUSTOM_MODEL_OPTION を使う (ピッカー最下部に1件追加)。
    env = {
      ANTHROPIC_CUSTOM_MODEL_OPTION = "claude-opus-4-6";
      ANTHROPIC_CUSTOM_MODEL_OPTION_NAME = "Opus 4.6";
      ANTHROPIC_CUSTOM_MODEL_OPTION_DESCRIPTION = "Opus 4.6 (legacy; agentic coding 用)";
    };
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

    # --- Marketplace registration ---
    MARKETPLACES='${builtins.toJSON {
      "openai-codex" = {
        source = { source = "github"; repo = "openai/codex-plugin-cc"; };
      };
    }}'

    if [ -f "$KNOWN" ]; then
      # Merge new marketplaces (won't overwrite existing entries)
      echo "$MARKETPLACES" | ${pkgs.jq}/bin/jq -s '.[1] as $new | .[0] | . * ($new | with_entries(select(.key as $k | (.[0] | keys | index($k)) | not)))' "$KNOWN" - > "$KNOWN.tmp" && mv "$KNOWN.tmp" "$KNOWN"
    else
      echo "$MARKETPLACES" | ${pkgs.jq}/bin/jq '.' > "$KNOWN"
    fi

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
  '';

  home.sessionVariables = {
    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
  };

  home.packages = [
    claude-code-pkg
  ];
}
