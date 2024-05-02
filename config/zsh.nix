{ pkgs, ... }:

{
  home.packages = with pkgs; [
    zsh-autosuggestions
    zsh-syntax-highlighting

    starship
    fzf
    ghq
  ];

  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "fzf"
        "z"
        "docker"
        "kubectl"
        "terraform"
      ];
    };

    history = {
      ignoreAllDups = true;
      path = "${config.xdg.dataHome}/zsh/history";
      save = 10000;
      size = 10000;
      share = true;
    };

    initExtra = ''
      bindkey -e
      bindkey "[D" backward-word
      bindkey "[C" forward-word

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
