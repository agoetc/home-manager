{ codex-pkg, lib, pkgs, ... }:

{
  home.file.".codex/AGENTS.md" = {
    source = ./AGENTS.md;
    force = true;
  };
  home.file.".codex/commands/review.md" = {
    source = ../claude/commands/review-user.md;
    force = true;
  };

  # Keep Codex MCP servers declarative while preserving other runtime config.
  home.activation.codexMcpServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    CODEX_CONFIG="$HOME/.codex/config.toml"
    TMP_FILE="$(mktemp)"

    MCP_BLOCK='[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp"]

[mcp_servers.playwright]
command = "npx"
args = ["-y", "@playwright/mcp@latest"]'

    mkdir -p "$HOME/.codex"

    if [ -f "$CODEX_CONFIG" ]; then
      ${pkgs.gawk}/bin/awk '
        BEGIN { skip = 0 }
        {
          if ($0 ~ /^\[mcp_servers\./) {
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
    printf '\n\n%s\n' "$MCP_BLOCK" >> "$TMP_FILE"
    mv "$TMP_FILE" "$CODEX_CONFIG"
  '';

  home.packages = [
    codex-pkg
  ];
}
