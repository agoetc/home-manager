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
    skipDangerousModePermissionPrompt = true;
    statusLine = {
      type = "command";
      command = "~/.claude/statusline.sh";
    };
    # Stop hook: ツール呼び出しがテキストに化けて未実行のまま終了した事故を検知し、
    # block して呼び直させる。スクリプトは hooks/ 配下 (再帰 symlink で ~/.claude/hooks/)。
    hooks = {
      Stop = [
        {
          hooks = [
            {
              type = "command";
              command = "bash ~/.claude/hooks/detect-leaked-toolcall.sh";
            }
          ];
        }
      ];
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

  # activation script は最小 PATH で走り新世代の claude が PATH に無い場合があるため、
  # plugin CLI は必ず絶対パスで呼ぶ (bare `claude` だと || true で握り潰され撤去が無言で失敗する)。
  claudeBin = "${claude-code-pkg}/bin/claude";

  # superpowers-marketplace から撤去するプラグイン群。
  # enabledPlugins からの削除と plugins/ 実体の uninstall に使う。
  removedPlugins = [
    "superpowers@superpowers-marketplace"
    "elements-of-style@superpowers-marketplace"
    "superpowers-developing-for-claude-code@superpowers-marketplace"
    "private-journal-mcp@superpowers-marketplace"
  ];

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

    # 撤去プラグインの enabledPlugins キーを削除。deep merge (.[0] * .[1]) では
    # 旧キーが温存され消えないため、明示的に delpaths する (存在しなければ no-op)。
    REMOVED_PLUGINS='${builtins.toJSON removedPlugins}'
    ${pkgs.jq}/bin/jq --argjson rm "$REMOVED_PLUGINS" \
      'delpaths([$rm[] | ["enabledPlugins", .]])' \
      "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

    # RTK (Rust Token Killer) 撤去: headroom wrap 経由で rtk init が settings.json へ
    # 直書きした PreToolUse(Bash) フックを削除。deep merge (.[0] * .[1]) は runtime キーを
    # 温存するため明示削除が必要 (Stop hook 等 rtk 以外は残す)。
    ${pkgs.jq}/bin/jq '
      if (.hooks.PreToolUse?) then
        .hooks.PreToolUse |= map(select(
          [.hooks[]?.command // ""] | any(test("rtk")) | not
        ))
      else . end
      | if ((.hooks.PreToolUse? | length) == 0) then del(.hooks.PreToolUse) else . end
    ' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

    # rtk 生成物 (nix 管理外) を除去
    rm -f "$HOME/.claude/RTK.md" "$HOME/.claude/hooks/rtk-rewrite.sh"
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
  home.activation.claudePlugins = lib.hm.dag.entryAfter [ "writeBoundary" "claudeSettings" ] ''
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
      ${claudeBin} plugin marketplace add "$mp_repo" 2>/dev/null || true
    }

    register_marketplace "openai-codex" "openai/codex-plugin-cc"

    # --- Plugin installation via CLI ---
    # Only install if not already in installed_plugins.json
    install_plugin() {
      local plugin_id="$1"
      if [ -f "$INSTALLED" ] && ${pkgs.jq}/bin/jq -e --arg p "$plugin_id" '.plugins[$p]' "$INSTALLED" > /dev/null 2>&1; then
        return 0
      fi
      echo "Installing Claude plugin: $plugin_id"
      ${claudeBin} plugin install "$plugin_id" 2>/dev/null || true
    }

    install_plugin "codex@openai-codex"

    # --- superpowers-marketplace 撤去 (install/merge は撤去を扱わないため明示) ---
    # plugins/ 実体を uninstall。enabledPlugins キー削除は claudeSettings 側で実施。
    uninstall_plugin() {
      local plugin_id="$1"
      if [ -f "$INSTALLED" ] && ${pkgs.jq}/bin/jq -e --arg p "$plugin_id" '.plugins[$p]' "$INSTALLED" > /dev/null 2>&1; then
        echo "Uninstalling Claude plugin: $plugin_id"
        ${claudeBin} plugin uninstall "$plugin_id" 2>/dev/null || true
      fi
    }

    uninstall_plugin "superpowers@superpowers-marketplace"
    uninstall_plugin "elements-of-style@superpowers-marketplace"
    uninstall_plugin "superpowers-developing-for-claude-code@superpowers-marketplace"
    uninstall_plugin "private-journal-mcp@superpowers-marketplace"

    # マーケットプレイス登録解除 (登録が残っている場合のみ)
    if [ -f "$KNOWN" ] && ${pkgs.jq}/bin/jq -e '."superpowers-marketplace".installLocation' "$KNOWN" > /dev/null 2>&1; then
      echo "Removing Claude marketplace: superpowers-marketplace"
      ${claudeBin} plugin marketplace remove superpowers-marketplace 2>/dev/null || true
    fi
  '';

  home.sessionVariables = {
    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
  };

  home.packages = [
    claude-code-pkg
  ];
}
