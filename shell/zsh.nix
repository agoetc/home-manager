{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;

    initExtraBeforeCompInit = ''
      # fzf
      source ${pkgs.fzf}/share/fzf/completion.zsh
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

      export HISTFILE=~/.zsh_history
      export HISTSIZE=10000
      export SAVEHIST=10000
      setopt HIST_IGNORE_DUPS
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "docker"
        "fzf"
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
  ];
}
