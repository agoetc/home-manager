{
  description = "Home Manager configuration of takegawa";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    # ssm-session-manager-plugin が壊れているため、動作する直前のリビジョンにピン留め
    # https://github.com/nixos/nixpkgs/issues/486267
    nixpkgs-ssm.url = "github:nixos/nixpkgs/5dd77cd60490fd0b23f4bb787150280a241e0e1b";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nix-darwin: システム領域 (/Library 等) を宣言的に管理。BlackHole 等の HAL ドライバ用
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Claude Code - 最新版を即座に使うためのローカルflake
    claude-code = {
      url = "path:./programs/claude";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Codex - 最新版を即座に使うためのローカルflake
    codex = {
      url = "path:./programs/codex";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-master, nixpkgs-ssm, home-manager, nix-darwin, sops-nix, claude-code, codex, ... }:
    let
      system = "aarch64-darwin";
      # direnv 2.37.1 の checkPhase (test-bash/test-zsh) が darwin でハングするため無効化
      overlays = [
        (final: prev: {
          direnv = prev.direnv.overrideAttrs (_: { doCheck = false; });
        })
      ];
      pkgs = import nixpkgs {
        inherit system overlays;
      };
      pkgs-master = import nixpkgs-master {
        inherit system overlays;
        config.allowUnfree = true;
      };
      pkgs-ssm = import nixpkgs-ssm {
        inherit system;
      };
      claude-code-pkg = claude-code.packages.${system}.default;
      codex-pkg = codex.packages.${system}.default;
    in
    {
      homeConfigurations."takegawa" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [
          ./home.nix
          sops-nix.homeManagerModules.sops
        ];

        extraSpecialArgs = { inherit pkgs-master pkgs-ssm claude-code-pkg codex-pkg; };
      };

      # nix-darwin: システム領域専用の最小構成 (home-manager standalone とは並存)
      # 適用: sudo darwin-rebuild switch --flake .#takegawanoMacBook-Pro
      darwinConfigurations."takegawanoMacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [
          { nixpkgs.pkgs = pkgs; }
          ./darwin.nix
        ];
      };
    };
}
