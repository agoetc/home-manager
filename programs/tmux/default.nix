{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    mouse = true;
    escapeTime = 0;
    historyLimit = 50000;

    extraConfig = ''
      # 拡張キー (CSI u) を有効化 — Ctrl+Enter 等のモディファイア付きキーをパススルー
      set -g extended-keys on
      set -as terminal-features 'xterm*:extkeys'

      # クリップボード連携 (macOS pbcopy)
      set -s copy-command 'pbcopy'
      set -s set-clipboard on

      # copy-mode で選択→コピー時にクリップボードへ送る
      bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel
      bind -T copy-mode    MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel
    '';
  };
}
