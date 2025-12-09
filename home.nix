{ config, pkgs, pkgs-master, ... }:

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

    # Last login メッセージを非表示
    file.".hushlogin".text = "";

    # colimaデフォルト設定テンプレート
    file.".colima/_templates/default.yaml".text = ''
      cpu: 6
      disk: 100
      memory: 16
      arch: x86_64
      runtime: docker
      hostname: ""
      kubernetes:
        enabled: true
    '';
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
      colima
      docker-client
      kubectl
      pkgs-master.claude-code
      pkgs-master.codex
      pkgs-master.k9s
    ];

  imports = [
    ./config/zsh.nix
    ./config/mise.nix
    ./config/aws.nix
    ./config/nvim.nix
    ./config/git.nix
  ];
}
