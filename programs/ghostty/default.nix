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

      # Window
      macos-titlebar-style = "tabs";
      window-padding-x = 8;
      window-padding-y = 8;
      window-padding-balance = true;

      # macOS
      macos-option-as-alt = "left";
      confirm-close-surface = false;

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
