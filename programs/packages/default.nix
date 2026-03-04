{ pkgs, pkgs-master, ... }:

{
  home.packages = with pkgs; [
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
