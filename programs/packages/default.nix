{ pkgs, pkgs-master, ... }:

let
  # dev キャッシュをまとめて削除するコマンド。`clean-caches` で実行。
  clean-caches = pkgs.writeShellScriptBin "clean-caches" ''
    set -u
    echo "== before =="
    df -h /System/Volumes/Data | tail -1

    echo "== uv =="
    command -v uv >/dev/null && uv cache clean || true
    echo "== yarn =="
    command -v yarn >/dev/null && yarn cache clean || true
    echo "== pnpm =="
    command -v pnpm >/dev/null && pnpm store prune || true
    echo "== coursier (scala) =="
    rm -rf "$HOME/Library/Caches/Coursier" 2>/dev/null || true
    echo "== github-copilot =="
    rm -rf "$HOME/.cache/github-copilot"/* 2>/dev/null || true
    echo "== spotify =="
    rm -rf "$HOME/Library/Caches/com.spotify.client"/* 2>/dev/null || true
    echo "== Xcode DerivedData / unavailable simulators =="
    rm -rf "$HOME/Library/Developer/Xcode/DerivedData"/* 2>/dev/null || true
    command -v xcrun >/dev/null && xcrun simctl delete unavailable 2>/dev/null || true

    echo "== after =="
    df -h /System/Volumes/Data | tail -1
    echo "tip: /nix/store は 'nix-collect-garbage -d' で削減 (自動GC設定済)"
  '';
in
{
  home.packages = with pkgs; [
    clean-caches
    gh
    difftastic
    jq
    wget
    mysql84
    online-judge-tools
    uv
    socat
    stripe-cli
    _1password-cli
    xlsx2csv
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
    ])
    kubectl
pkgs-master.k9s
    # CLI tools
    ripgrep
    fd
    eza
    minio-client
    lazygit
    lazydocker
    ollama
    ffmpeg
  ];
}
