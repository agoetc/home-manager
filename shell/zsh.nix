{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;

    initExtraBeforeCompInit = ''
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      source ${pkgs.git}/share/bash-completion/completions/git-prompt.sh
      source ${pkgs.docker}/share/zsh/site-functions/_docker

      # fzf
      source ${pkgs.fzf}/share/fzf/completion.zsh
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

      export HISTFILE=~/.zsh_history
      export HISTSIZE=10000
      export SAVEHIST=10000
      setopt HIST_IGNORE_DUPS
      bindkey '^R' fzf-history-widget
    '';
  };

  programs.starship = {
    enable = true;
  };

  home.sessionVariables = {
    EDITOR = "vim";
  };

  home.packages = with pkgs; [
    zsh
    fzf
    zsh-fzf-tab
    ghq
    zsh-completions
    zsh-autosuggestions
    zsh-syntax-highlighting
    starship # theme
  ];
}
