{ pkgs, ... }:

{
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;

    extraConfig = ''
      local config = wezterm.config_builder()

      -- Font
      config.font = wezterm.font("MesloLGS NF")
      config.font_size = 13.0

      -- Color Scheme (Dracula to match Neovim)
      config.color_scheme = "Dracula (Official)"

      -- Window / Appearance
      config.window_decorations = "RESIZE"
      config.window_padding = {
        left = 8,
        right = 8,
        top = 8,
        bottom = 8,
      }
      config.initial_cols = 120
      config.initial_rows = 35
      config.hide_tab_bar_if_only_one_tab = true
      config.window_close_confirmation = "NeverPrompt"

      -- macOS
      config.native_macos_fullscreen_mode = false
      config.send_composed_key_when_left_alt_is_pressed = false
      config.send_composed_key_when_right_alt_is_pressed = true

      -- Japanese IME
      config.use_ime = true
      config.macos_forward_to_ime_modifier_mask = "SHIFT|CTRL"

      -- Cursor
      config.default_cursor_style = "BlinkingBlock"
      config.cursor_blink_rate = 500

      -- Scrollback
      config.scrollback_lines = 10000

      -- Bell
      config.audible_bell = "Disabled"
      config.visual_bell = {
        fade_in_duration_ms = 75,
        fade_out_duration_ms = 75,
        target = "CursorColor",
      }

      -- GPU
      config.front_end = "WebGpu"

      -- Key Bindings
      config.keys = {
        { mods = "OPT", key = "LeftArrow",  action = wezterm.action.SendKey({ mods = "ALT", key = "b" }) },
        { mods = "OPT", key = "RightArrow", action = wezterm.action.SendKey({ mods = "ALT", key = "f" }) },
        { mods = "CMD", key = "LeftArrow",  action = wezterm.action.SendKey({ mods = "CTRL", key = "a" }) },
        { mods = "CMD", key = "RightArrow", action = wezterm.action.SendKey({ mods = "CTRL", key = "e" }) },
        { mods = "CMD", key = "Backspace",  action = wezterm.action.SendKey({ mods = "CTRL", key = "u" }) },
        { mods = "OPT", key = "Backspace",  action = wezterm.action.SendKey({ mods = "CTRL", key = "w" }) },
        { mods = "CMD", key = "d", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
        { mods = "CMD|SHIFT", key = "d", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
      }

      return config
    '';
  };
}
