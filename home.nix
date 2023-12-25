{ config, pkgs, ... }:

{
    # ユーザ情報
    home.username = "takegawa";
    home.homeDirectory = "/Users/takegawa";

    nixpkgs.config = {
        allowUnfree = true;
    };

    home.stateVersion = "24.05";
    programs.home-manager.enable = true;

    imports = [
        ./shell/zsh.nix
        # ./shell/fish.nix
    ];
}
