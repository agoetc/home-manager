{ pkgs, ... }:

{
  home.packages = with pkgs; [
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    zsh-fzf-tab
    zsh-powerlevel10k
    nix-zsh-completions
    fzf
    ghq
    just
    zoxide
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;

    completionInit = ''
      # nix-profile の補完を読み込む
      fpath+=~/.nix-profile/share/zsh/site-functions

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
      kp = "f() { lsof -ti:$1 | xargs kill -9 2>/dev/null || echo \"No process on port $1\"; }; f";
      # eza
      ls = "eza";
      ll = "eza -la";
      la = "eza -a";
      lt = "eza --tree";
    };

    initContent = ''
      # ============================================
      # Powerlevel10k Instant Prompt (最初に読み込む)
      # ============================================
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      # ============================================
      # 環境設定
      # ============================================
      if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi

      # nix-profile の補完を有効化
      fpath=(~/.nix-profile/share/zsh/site-functions $fpath)
      autoload -Uz compinit && compinit

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
      source $HOME/.config/home-manager/shell/ghq-zsh.sh

      # just
      [ -e "${pkgs.just}/share/zsh/site-functions/_just" ] && \
        source "${pkgs.just}/share/zsh/site-functions/_just"

      # zoxide
      eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"

      # ni (package manager switcher)
      command -v ni &>/dev/null && eval "$(ni --completion-zsh)"
      command -v nr &>/dev/null && eval "$(nr --completion-zsh)"

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

      # 3. autosuggestions
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh

      # 4. powerlevel10k (最後)
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

      # ============================================
      # iTerm2 Shell Integration
      # ============================================
      test -e "$HOME/.iterm2_shell_integration.zsh" && source "$HOME/.iterm2_shell_integration.zsh"
    '';
  };
}
