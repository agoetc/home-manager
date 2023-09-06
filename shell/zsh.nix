{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    
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
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

      # ghq
      source $HOME/.config/home-manager/shell/ghq-zsh.sh

      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "docker"
        "fzf"
        "z"
      ];
    };

  };

  programs.starship = {
    enable = true;
  };

  home.sessionVariables = {
    EDITOR = "vim";
  };

  home.packages = with pkgs; [
    zsh
    oh-my-zsh
    fzf
    zsh-fzf-tab
    ghq
    zsh-completions
    zsh-autosuggestions
    zsh-syntax-highlighting
    starship # theme

    asdf-vm
  ];
}
