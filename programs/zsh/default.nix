{ pkgs, ... }:

{
  home.packages = with pkgs; [
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    zsh-fzf-tab
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

      # compinit を1日1回だけ再生成（-C で既存キャッシュを再利用）
      autoload -Uz compinit
      if [[ -n ''${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
        compinit
      else
        compinit -C
      fi

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
      clauded = "claude --dangerously-skip-permissions";
      # Home-Manager Switch: ローカルflake更新 → git add → flake update → switch
      hms = "~/.config/home-manager/programs/claude/update.sh && ~/.config/home-manager/programs/codex/update.sh && cd ~/.config/home-manager && git add -A && nix flake update && home-manager switch";
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
      source $HOME/.config/home-manager/programs/zsh/ghq-zsh.sh

      # zoxide (--cmd cd で cd を置き換え、遅延なし)
      eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"

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

      # ============================================
      # iTerm2 Shell Integration
      # ============================================
      test -e "$HOME/.iterm2_shell_integration.zsh" && source "$HOME/.iterm2_shell_integration.zsh"

    '';
  };

  # Starship prompt (Pure風)
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      # Pure風: 2行フォーマット
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";

      directory.style = "cyan";

      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };

      git_branch = {
        format = "[$branch]($style) ";
        style = "bright-black";
      };

      git_status = {
        format = "[$all_status$ahead_behind]($style) ";
        style = "cyan";
      };

      cmd_duration = {
        format = "[$duration]($style) ";
        style = "yellow";
        min_time = 2000;
      };
    };
  };
}
