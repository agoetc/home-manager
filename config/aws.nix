{ pkgs, pkgs-ssm, ... }:

{
    home.packages = [
        pkgs.awscli2
        # https://github.com/nixos/nixpkgs/issues/486267
        pkgs-ssm.ssm-session-manager-plugin
    ];
}
