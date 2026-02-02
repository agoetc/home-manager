{
  description = "Home Manager configuration of takegawa";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    grepai.url = "github:yoanbernabeu/grepai";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-master, home-manager, grepai, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-master = import nixpkgs-master {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      homeConfigurations."takegawa" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [ ./home.nix ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
        extraSpecialArgs = {
          inherit pkgs-master;
          grepai-pkg = pkgs.buildGoModule {
            pname = "grepai";
            version = "0.18.0";
            src = grepai;
            vendorHash = "sha256-doGLaRDqD2c3MvUGkeBHuQ4rmnoUemqb1IhEwy+7G40=";
            ldflags = [ "-s" "-w" "-X main.version=0.18.0" ];
            meta.mainProgram = "grepai";
          };
        };
      };
    };
}
