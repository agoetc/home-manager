{ config, pkgs, pkgs-master, pkgs-ssm, ... }:

{
  # アンフリーライセンスのパッケージを許可
  nixpkgs.config.allowUnfree = true;

  programs.home-manager = {
    enable = true;
  };

  home = {
    username = "takegawa";
    homeDirectory = "/Users/takegawa";
    stateVersion = "24.05";

    # ~/.local/bin を PATH に追加 (Claude Code native install 等)
    sessionPath = [ "$HOME/.local/bin" ];

    # Last login メッセージを非表示
    file.".hushlogin".text = "";

    # ~/.local/bin ディレクトリを確保
    file.".local/bin/.keep".text = "";
  };


  # 設定や依存のないものだけここで定義
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
    ];

  imports = [
    ./config/zsh.nix
    ./config/mise.nix
    ./config/aws.nix
    ./config/nvim.nix
    ./config/git.nix
    ./config/gwq.nix
    ./config/claude.nix
    ./config/codex.nix
    ./config/iterm2.nix
    ./config/ssh.nix
  ];
}
