{ config, pkgs, ... }:

{
    home.packages = with pkgs; [
        # cli系
        git
        gh
        jq
        just

        # zsh系
        zsh
        oh-my-zsh # plugin manager
        fzf
        ghq
        zsh-completions
        zsh-autosuggestions
        zsh-syntax-highlighting
        starship # theme

        # asdf
        asdf-vm
    ];

    programs.starship = {
        enable = true;
    };

    programs.zsh = {
        enable = true;

        oh-my-zsh = {
            enable = true;
            plugins = [
                "git"
                "docker"
                "fzf"
                "z"
            ];
        };

        initExtra = ''
            bindkey -e

            export HISTFILE=~/.zsh_history
            export HISTSIZE=10000
            export SAVEHIST=10000
            setopt HIST_IGNORE_DUPS

            # asdf
            source ${pkgs.asdf-vm}/share/zsh/site-functions/_asdf
            . "$HOME/.nix-profile/share/asdf-vm/asdf.sh"
            . "$HOME/.asdf/plugins/java/set-java-home.bash"

            alias dc="docker compose"

            # fzf
            source ${pkgs.fzf}/share/fzf/key-bindings.zsh

            # ghq
            export GHQ_ROOT="$HOME/Work";
            source $HOME/.config/home-manager/shell/ghq-zsh.sh

            source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
            source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
        '';
    };
}
