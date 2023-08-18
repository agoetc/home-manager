{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;

    initExtraBeforeCompInit = ''
      # fzf
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

      export HISTFILE=~/.zsh_history
      export HISTSIZE=10000
      export SAVEHIST=10000
      setopt HIST_IGNORE_DUPS

      # asdf
      source ${pkgs.asdf-vm}/share/zsh/site-functions/_asdf
      . "$HOME/.nix-profile/share/asdf-vm/asdf.sh"
      . "$HOME/.asdf/plugins/java/set-java-home.bash"

      alias dc="docker compose"
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
