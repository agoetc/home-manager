{ pkgs, ... }:

{
  home.packages = with pkgs; [
    zsh-autosuggestions
    zsh-syntax-highlighting

    starship
    fzf
    ghq
    just
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
        "fzf"
        "z"
        "docker"
        "kubectl"
        "terraform"
        "aws"
      ];
    };

    history = {
      ignoreAllDups = true;
      path = "$HOME/zsh/history";
      save = 10000;
      size = 10000;
      share = true;
    };

    shellAliases = {
      dc = "docker compose";
      d = "docker";
      sail = "[ -f sail ] && sh sail || sh vendor/bin/sail";
    };

    initContent = ''
      # Nix環境の読み込み
      if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi

      bindkey -e
      bindkey "[D" backward-word
      bindkey "[C" forward-word

      # fzf
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh

      # ghq
      export GHQ_ROOT="$HOME/Work";
      source $HOME/.config/home-manager/shell/ghq-zsh.sh

      # just completion
      if [ -e "${pkgs.just}/share/zsh/site-functions/_just" ]; then
        source "${pkgs.just}/share/zsh/site-functions/_just"
      fi

      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    '';
  };
}
