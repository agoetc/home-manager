{ pkgs, lib, ... }:

let
  # Dynamic Profiles の設定
  # 現在のiTerm2プロファイルから出力したJSONを元に作成
  # 参考: https://iterm2.com/documentation-dynamic-profiles.html
  dynamicProfiles = {
    Profiles = [
      {
        # 基本情報
        Name = "Nix Default";
        Guid = "nix-default-profile-001";
        Description = "Nix-managed iTerm2 profile";

        # シェル・ディレクトリ設定
        "Custom Command" = "No";
        "Custom Directory" = "Recycle";
        "Working Directory" = "/Users/takegawa";

        # フォント設定
        "Normal Font" = "MesloLGS-NF-Regular 13";
        "Non Ascii Font" = "Monaco 12";
        "Use Non-ASCII Font" = false;
        "Use Bold Font" = true;
        "Use Italic Font" = true;
        "ASCII Anti Aliased" = true;
        "Non-ASCII Anti Aliased" = true;
        "Draw Powerline Glyphs" = true;

        # ウィンドウ設定
        Columns = 120;
        Rows = 35;
        "Window Type" = 0;
        "Disable Window Resizing" = true;
        Transparency = 0;
        Blur = false;

        # カーソル設定
        "Cursor Type" = 1;  # 0=Underline, 1=Vertical bar, 2=Box
        "Blinking Cursor" = true;

        # スクロール設定
        "Scrollback Lines" = 10000;
        "Unlimited Scrollback" = true;

        # ベル設定
        "Silence Bell" = true;
        "Visual Bell" = true;
        "Flashing Bell" = false;
        "BM Growl" = true;

        # ターミナル設定
        "Terminal Type" = "xterm-256color";
        "Character Encoding" = 4;
        "Mouse Reporting" = true;
        "Option Key Sends" = 2;
        "Right Option Key Sends" = 2;

        # 表示設定
        "Horizontal Spacing" = 1;
        "Vertical Spacing" = 1;
        "Use Bright Bold" = true;
        "Minimum Contrast" = 0;

        # セッション終了時の動作
        "Close Sessions On End" = 1;
        "Prompt Before Closing 2" = false;

        # 無視するジョブ
        "Jobs to Ignore" = [ "rlogin" "ssh" "slogin" "telnet" ];

        # カラー設定 (Dark)
        "Use Separate Colors for Light and Dark Mode" = false;

        # 前景色・背景色
        "Foreground Color" = {
          "Red Component" = 0.73333334922790527;
          "Green Component" = 0.73333334922790527;
          "Blue Component" = 0.73333334922790527;
        };
        "Background Color" = {
          "Red Component" = 0;
          "Green Component" = 0;
          "Blue Component" = 0;
        };

        # カーソル色
        "Cursor Color" = {
          "Red Component" = 0.73333334922790527;
          "Green Component" = 0.73333334922790527;
          "Blue Component" = 0.73333334922790527;
        };
        "Cursor Text Color" = {
          "Red Component" = 1;
          "Green Component" = 1;
          "Blue Component" = 1;
        };

        # 選択色
        "Selection Color" = {
          "Red Component" = 0.70980000495910645;
          "Green Component" = 0.8353000283241272;
          "Blue Component" = 1;
        };
        "Selected Text Color" = {
          "Red Component" = 0;
          "Green Component" = 0;
          "Blue Component" = 0;
        };

        # ボールド色
        "Bold Color" = {
          "Red Component" = 1;
          "Green Component" = 1;
          "Blue Component" = 1;
        };

        # ANSI カラー (0-15)
        "Ansi 0 Color" = { "Red Component" = 0; "Green Component" = 0; "Blue Component" = 0; };
        "Ansi 1 Color" = { "Red Component" = 0.73333334922790527; "Green Component" = 0; "Blue Component" = 0; };
        "Ansi 2 Color" = { "Red Component" = 0; "Green Component" = 0.73333334922790527; "Blue Component" = 0; };
        "Ansi 3 Color" = { "Red Component" = 0.73333334922790527; "Green Component" = 0.73333334922790527; "Blue Component" = 0; };
        "Ansi 4 Color" = { "Red Component" = 0; "Green Component" = 0; "Blue Component" = 0.73333334922790527; };
        "Ansi 5 Color" = { "Red Component" = 0.73333334922790527; "Green Component" = 0; "Blue Component" = 0.73333334922790527; };
        "Ansi 6 Color" = { "Red Component" = 0; "Green Component" = 0.73333334922790527; "Blue Component" = 0.73333334922790527; };
        "Ansi 7 Color" = { "Red Component" = 0.73333334922790527; "Green Component" = 0.73333334922790527; "Blue Component" = 0.73333334922790527; };
        "Ansi 8 Color" = { "Red Component" = 0.3333333432674408; "Green Component" = 0.3333333432674408; "Blue Component" = 0.3333333432674408; };
        "Ansi 9 Color" = { "Red Component" = 1; "Green Component" = 0.3333333432674408; "Blue Component" = 0.3333333432674408; };
        "Ansi 10 Color" = { "Red Component" = 0.3333333432674408; "Green Component" = 1; "Blue Component" = 0.3333333432674408; };
        "Ansi 11 Color" = { "Red Component" = 1; "Green Component" = 1; "Blue Component" = 0.3333333432674408; };
        "Ansi 12 Color" = { "Red Component" = 0.3333333432674408; "Green Component" = 0.3333333432674408; "Blue Component" = 1; };
        "Ansi 13 Color" = { "Red Component" = 1; "Green Component" = 0.3333333432674408; "Blue Component" = 1; };
        "Ansi 14 Color" = { "Red Component" = 0.3333333432674408; "Green Component" = 1; "Blue Component" = 1; };
        "Ansi 15 Color" = { "Red Component" = 1; "Green Component" = 1; "Blue Component" = 1; };

        # キーボードマッピング
        "Keyboard Map" = {
          "0xf728-0x0" = { Action = 11; Text = "0x4"; };
          "0xf702-0x280000" = { Version = 2; "Apply Mode" = 0; Action = 10; Text = "b"; Escaping = 1; };
          "0xf702-0x300000" = { Action = 11; Text = "0x1"; };
          "0xf703-0x280000" = { Action = 10; Text = "f"; };
          "0x7f-0x100000" = { Action = 11; Text = "0x15"; };
          "0xf703-0x300000" = { Action = 11; Text = "0x5"; };
          "0xf728-0x80000" = { Action = 10; Text = "d"; };
          "0x7f-0x80000" = { Action = 11; Text = "\"0x1b 0x7f\""; };
        };

        # トリガー
        Triggers = [
          {
            partial = true;
            parameter = 0;
            regex = "(DAI-\\d+)\n\n\nDAI-\\d+";
            action = "BounceTrigger";
          }
        ];

        # Semantic History（Cmd+クリックでファイルを開く）
        "Semantic History" = {
          editor = "nvim";
          action = "best editor";
        };
      }
    ];
  };
in
{
  # Dynamic Profiles を配置
  home.file."Library/Application Support/iTerm2/DynamicProfiles/nix-profiles.json" = {
    text = builtins.toJSON dynamicProfiles;
  };

  # iTerm2 Shell Integration スクリプトを配置
  home.file.".iterm2_shell_integration.zsh" = {
    source = pkgs.fetchurl {
      url = "https://iterm2.com/shell_integration/zsh";
      sha256 = "sha256-kQJ8bVIh7nEjYJ6OWqiEDqIY+YWD5RbD1CXV+KKyDno=";
    };
  };
}
