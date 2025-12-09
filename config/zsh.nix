{ pkgs, ... }:

{
  home.packages = with pkgs; [
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    zsh-fzf-tab

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
    enableCompletion = true;

    completionInit = ''
      autoload -Uz compinit && compinit

      # 大文字小文字を無視
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

      # メニュー選択モード（Tab連打で選択できる）
      zstyle ':completion:*' menu select

      # 補完候補をグループ化して表示
      zstyle ':completion:*' group-name '''
      zstyle ':completion:*:descriptions' format '%B%d%b'

      # キャッシュを有効化（高速化）
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path ~/.zsh/cache

      # 補完候補に色をつける
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
    '';

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
      # ============================================
      # 環境設定
      # ============================================
      if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi

      # ============================================
      # キーバインド
      # ============================================
      bindkey -e
      bindkey "[D" backward-word
      bindkey "[C" forward-word

      # ============================================
      # ツール設定
      # ============================================
      # fzf
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh

      # ghq
      export GHQ_ROOT="$HOME/Work"
      source $HOME/.config/home-manager/shell/ghq-zsh.sh

      # just
      [ -e "${pkgs.just}/share/zsh/site-functions/_just" ] && \
        source "${pkgs.just}/share/zsh/site-functions/_just"

      # ============================================
      # zshプラグイン (読み込み順序に注意)
      # ============================================
      # 1. fzf-tab (syntax-highlightingより前)
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color=always $realpath'
      zstyle ':fzf-tab:complete:*:*' fzf-preview 'less ''${(Q)realpath}'
      zstyle ':fzf-tab:*' fzf-flags --height=40%

      # 2. syntax-highlighting
      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

      # 3. autosuggestions (最後)
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    '';
  };
}
