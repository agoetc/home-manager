{ config, pkgs, ... }:

{
    # ユーザ情報
    home = {
        username = "takegawa";
        homeDirectory = "/Users/takegawa";

        sessionVariables = {
            EDITOR = "vim";
        };

        stateVersion = "24.05";
    };

    nixpkgs.config = {
        allowUnfree = true;
    };

    programs.home-manager.enable = true;

    imports = [
        ./shell/zsh.nix
        # ./shell/fish.nix
    ];
}
