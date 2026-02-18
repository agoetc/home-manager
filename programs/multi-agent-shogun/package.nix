{ lib
, stdenvNoCC
, fetchFromGitHub
, makeWrapper
, python3
, tmux
, fswatch
, coreutils
, rsync
}:

let
  version = "3.4";
  python = python3.withPackages (ps: [ ps.pyyaml ]);

  runtimeDeps = lib.makeBinPath [
    python
    tmux
    fswatch
    coreutils
    rsync
  ];
in
stdenvNoCC.mkDerivation {
  pname = "multi-agent-shogun";
  inherit version;

  src = fetchFromGitHub {
    owner = "yohey-w";
    repo = "multi-agent-shogun";
    rev = "v${version}";
    hash = "sha256-xO6mNxxbUHiQPHWshfZ0qK3DVV4hDATTLRNbz6j4R+U=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # Install source files
    local shareDir="$out/share/multi-agent-shogun"
    mkdir -p "$shareDir"
    cp -r . "$shareDir/"

    # Create wrapper script
    mkdir -p "$out/bin"
    cat > "$out/bin/shogun" << 'WRAPPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

SHOGUN_VERSION="@version@"
SHOGUN_SRC="@src@"
SHOGUN_HOME="''${SHOGUN_HOME:-''${XDG_DATA_HOME:-$HOME/.local/share}/multi-agent-shogun}"

# Mutable directories (preserved across updates)
readonly MUTABLE_DIRS=(queue config status logs memory demo_output skills saytask)

sync_from_store() {
  echo "multi-agent-shogun v''${SHOGUN_VERSION} syncing..."

  mkdir -p "$SHOGUN_HOME"

  # Build rsync exclude list for mutable dirs
  local excludes=()
  for dir in "''${MUTABLE_DIRS[@]}"; do
    excludes+=(--exclude="/$dir/")
  done
  excludes+=(--exclude='/.venv/')
  excludes+=(--exclude='/.nix-version')

  # Sync immutable files from Nix store (chmod: Nix store files are read-only)
  rsync -a --delete --chmod=Du+rwx,Fu+rw "''${excludes[@]}" "$SHOGUN_SRC/" "$SHOGUN_HOME/"

  # Create mutable directories
  for dir in "''${MUTABLE_DIRS[@]}"; do
    mkdir -p "$SHOGUN_HOME/$dir"
  done
  mkdir -p "$SHOGUN_HOME/queue/tasks"
  mkdir -p "$SHOGUN_HOME/queue/reports"

  # Symlink python3 (Nix provides python3 + pyyaml)
  mkdir -p "$SHOGUN_HOME/.venv/bin"
  ln -sf "$(command -v python3)" "$SHOGUN_HOME/.venv/bin/python3"
  ln -sf "$(command -v pip3)" "$SHOGUN_HOME/.venv/bin/pip" 2>/dev/null || true

  # Make scripts executable
  find "$SHOGUN_HOME" -name '*.sh' -type f -exec chmod +x {} +

  echo "$SHOGUN_VERSION" > "$SHOGUN_HOME/.nix-version"
  echo "multi-agent-shogun v''${SHOGUN_VERSION} ready!"
}

# Sync on version mismatch or first run
current_version=""
if [[ -f "$SHOGUN_HOME/.nix-version" ]]; then
  current_version=$(cat "$SHOGUN_HOME/.nix-version")
fi
if [[ "$current_version" != "$SHOGUN_VERSION" ]]; then
  sync_from_store
fi

cd "$SHOGUN_HOME"
exec ./shutsujin_departure.sh "$@"
WRAPPER_EOF

    substituteInPlace "$out/bin/shogun" \
      --replace-warn "@version@" "${version}" \
      --replace-warn "@src@" "$shareDir"
    chmod +x "$out/bin/shogun"

    wrapProgram "$out/bin/shogun" \
      --prefix PATH : "${runtimeDeps}"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Samurai-inspired multi-agent system for Claude Code";
    homepage = "https://github.com/yohey-w/multi-agent-shogun";
    license = licenses.mit;
    mainProgram = "shogun";
  };
}
