{ pkgs, ... }:

{
    home.packages = with pkgs; [
      asdf-vm
    ];
    programs.zsh = {
        initContent = ''
            # asdf
            source ${pkgs.asdf-vm}/share/zsh/site-functions/_asdf
            . "$HOME/.nix-profile/share/asdf-vm/asdf.sh"
            . "$HOME/.asdf/plugins/java/set-java-home.bash"
        '';
    };
}
