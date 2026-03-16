{ codex-pkg, lib, pkgs, config, ... }:

let
  mcpServers = {
    context7 = {
      command = "npx";
      args = [ "-y" "@upstash/context7-mcp" ];
    };
    memory = {
      command = "npx";
      args = [ "-y" "@modelcontextprotocol/server-memory" ];
    };
    playwright = {
      command = "npx";
      args = [ "-y" "@playwright/mcp@latest" ];
    };
    sequential-thinking = {
      command = "npx";
      args = [ "-y" "@modelcontextprotocol/server-sequential-thinking" ];
    };
  };
in
{
  home.file.".codex/AGENTS.md" = {
    source = ./AGENTS.md;
    force = true;
  };
  home.file.".codex/skills" = {
    source = ./skills;
    recursive = true;
    force = true;
  };
  home.file.".codex/commands/review.md" = {
    source = ../claude/commands/review-user.md;
    force = true;
  };

  # Keep Codex MCP servers declarative while preserving other runtime config.
  home.activation.codexMcpServers = lib.hm.dag.entryAfter [ "sops-nix" "writeBoundary" ] ''
    CODEX_CONFIG="$HOME/.codex/config.toml"
    TMP_FILE="$(mktemp)"
    MANAGED_BLOCK_FILE="$(mktemp)"
    MANAGED_SERVERS_FILE="$(mktemp)"
    LOCAL_MCP="$HOME/.claude/local-mcp-servers.json"
    NOTION_SECRET="${config.sops.secrets.notion_token.path}"
    MANAGED_BEGIN="# >>> home-manager managed mcp servers >>>"
    MANAGED_END="# <<< home-manager managed mcp servers <<<"
    MCP_SERVERS='${builtins.toJSON mcpServers}'

    mkdir -p "$HOME/.codex"

    if [ -f "$NOTION_SECRET" ] && [ -s "$NOTION_SECRET" ]; then
      NOTION_TOKEN=$(cat "$NOTION_SECRET")
      NOTION_HEADERS="{\"Authorization\": \"Bearer $NOTION_TOKEN\", \"Notion-Version\": \"2025-09-03\"}"
      MCP_SERVERS=$(echo "$MCP_SERVERS" | ${pkgs.jq}/bin/jq \
        --arg headers "$NOTION_HEADERS" \
        '. + {notion: {command: "npx", args: ["-y", "@notionhq/notion-mcp-server"], env: {OPENAPI_MCP_HEADERS: $headers}}}')
    else
      echo "WARNING: notion_token secret is empty. Skipping notion MCP server." >&2
    fi

    if [ -f "$LOCAL_MCP" ]; then
      MCP_SERVERS=$(echo "$MCP_SERVERS" | ${pkgs.jq}/bin/jq --slurpfile local "$LOCAL_MCP" '. + $local[0]')
    fi

    echo "$MCP_SERVERS" | ${pkgs.jq}/bin/jq -r 'keys[]' > "$MANAGED_SERVERS_FILE"

    if [ -f "$CODEX_CONFIG" ]; then
      ${pkgs.gawk}/bin/awk -v managed_servers_file="$MANAGED_SERVERS_FILE" -v managed_begin="$MANAGED_BEGIN" -v managed_end="$MANAGED_END" '
        BEGIN {
          skip = 0
          in_managed_block = 0
          while ((getline server < managed_servers_file) > 0) {
            managed[server] = 1
          }
          close(managed_servers_file)
        }
        $0 == managed_begin {
          in_managed_block = 1
          next
        }
        $0 == managed_end {
          in_managed_block = 0
          next
        }
        in_managed_block {
          next
        }
        {
          if (match($0, /^\[mcp_servers\.([^. \]]+)/, header) && (header[1] in managed)) {
            skip = 1
            next
          }
          if (skip && $0 ~ /^\[/) {
            skip = 0
          }
          if (!skip) {
            print
          }
        }
      ' "$CODEX_CONFIG" > "$TMP_FILE"
    else
      : > "$TMP_FILE"
    fi

    echo "$MCP_SERVERS" | ${pkgs.jq}/bin/jq -r '
      def toml_scalar:
        if type == "string" then
          @json
        elif type == "number" or type == "boolean" then
          tostring
        elif type == "array" then
          "[" + (map(
            if type == "string" then
              @json
            elif type == "number" or type == "boolean" then
              tostring
            else
              error("unsupported array item type")
            end
          ) | join(", ")) + "]"
        else
          error("unsupported scalar type")
        end;

      $ARGS.named.begin,
      (
        to_entries[] as $server
        | "[mcp_servers.\($server.key)]",
          (
            $server.value
            | to_entries[]
            | select(.value | type != "object")
            | "\(.key) = \(.value | toml_scalar)"
          ),
          (
            $server.value
            | to_entries[]
            | select((.value | type) == "object" and (.value | length) > 0)
            | . as $nested
            | "",
              "[mcp_servers.\($server.key).\($nested.key)]",
              (
                $nested.value
                | to_entries[]
                | "\(.key) = \(.value | toml_scalar)"
              )
          ),
          ""
      ),
      $ARGS.named.end
    ' --arg begin "$MANAGED_BEGIN" --arg end "$MANAGED_END" > "$MANAGED_BLOCK_FILE"

    # Normalize and append the managed MCP section.
    ${pkgs.gawk}/bin/awk '
      { lines[NR] = $0 }
      NF { last = NR }
      END {
        for (i = 1; i <= last; i++) {
          print lines[i]
        }
      }
    ' "$TMP_FILE" > "$TMP_FILE.trimmed"
    mv "$TMP_FILE.trimmed" "$TMP_FILE"

    if [ -s "$TMP_FILE" ]; then
      printf '\n\n' >> "$TMP_FILE"
    fi
    cat "$MANAGED_BLOCK_FILE" >> "$TMP_FILE"

    mv "$TMP_FILE" "$CODEX_CONFIG"
    rm -f "$MANAGED_BLOCK_FILE" "$MANAGED_SERVERS_FILE"
  '';

  home.packages = [
    codex-pkg
  ];
}
