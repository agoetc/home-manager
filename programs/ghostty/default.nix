{ ... }:

{
  programs.ghostty = {
    enable = true;
    # macOS (aarch64-darwin) では Nix パッケージ未提供のため、brew cask / dmg で別途インストール
    package = null;
    enableZshIntegration = true;

    settings = {
      # Font
      font-family = "MesloLGS NF";
      font-size = 16;

      # Theme (Dracula to match Neovim)
      theme = "Dracula";

      # Background (Liquid Glass / macOS 26 Tahoe)
      # macos-glass-regular は OS ネイティブのガラス質感。opacity を 1 未満にして透過を効かせる
      background-opacity = 0.9;
      background-blur = "macos-glass-regular";

      # Window
      macos-titlebar-style = "tabs";
      window-padding-x = 8;
      window-padding-y = 8;
      window-padding-balance = true;

      # macOS
      macos-option-as-alt = "left";
      # Cmd+Q / surface close で毎回確認ダイアログを出す (誤爆防止。プロセス未実行でも確認)
      confirm-close-surface = "always";

      # 再起動時にウィンドウ/タブ/スクロールバックを復元
      window-save-state = "always";

      # 自動アップデート (本体は nix/brew 管理外の DMG 手動インストールのため内蔵 Sparkle に任せる)
      auto-update = "check";
      auto-update-channel = "stable";

      # Quick Terminal: OS 全体ホットキー Cmd+Shift+` でドロップダウン端末をトグル
      # (global: は他アプリ最前面でも反応。要 macOS アクセシビリティ権限)
      # cmd+` は macOS のかな変換に明け渡すため shift を足して衝突回避
      quick-terminal-position = "top";
      keybind = [ "global:cmd+shift+grave_accent=toggle_quick_terminal" ];

      # Cursor
      cursor-style = "block";
      cursor-style-blink = true;

      # Scrollback
      scrollback-limit = 50000;

      # Clipboard
      copy-on-select = "clipboard";
      clipboard-paste-protection = false;

      # Mouse
      mouse-hide-while-typing = true;

      # Bell
      bell-features = "no-audio,no-attention,no-title,no-system,no-border";
    };
  };
}
