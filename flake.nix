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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Claude Code - 最新版を即座に使うためのローカルflake
    claude-code = {
      url = "path:./programs/claude";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-master, nixpkgs-ssm, home-manager, sops-nix, claude-code, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-master = import nixpkgs-master {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-ssm = import nixpkgs-ssm {
        inherit system;
      };
      claude-code-pkg = claude-code.packages.${system}.default;
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

        extraSpecialArgs = { inherit pkgs-master pkgs-ssm claude-code-pkg; };
      };
    };
}
