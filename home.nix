{ config, pkgs, pkgs-master, pkgs-ssm, lib, ... }:

{
  # アンフリーライセンスのパッケージを許可
  nixpkgs.config.allowUnfree = true;

  programs.home-manager.enable = true;

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

  # sops-nix: シークレット管理
  sops = {
    age.keyFile = "${config.home.homeDirectory}/Library/Application Support/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      notion_token = { };
    };
  };

  imports = [
    ./programs/aws/default.nix
    ./programs/claude/default.nix
    ./programs/codex/default.nix
    ./programs/ghostty/default.nix
    ./programs/git/default.nix
    ./programs/gwq/default.nix
    ./programs/iterm2/default.nix
    ./programs/mise/default.nix
    ./programs/nvim/default.nix
    ./programs/packages/default.nix
    ./programs/ssh/default.nix
    ./programs/tmux/default.nix
    ./programs/wezterm/default.nix
    ./programs/zsh/default.nix
  ];
}
