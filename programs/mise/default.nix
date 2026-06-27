{ pkgs, ... }:

{
  programs.mise = {
    enable = true;
    # Nix ビルドサンドボックスは setuid/setgid ビットを保持できず、
    # mise の oci::layer 権限保持テストが落ちてビルド失敗するため checkPhase を無効化。
    # (mise 本体のバグではなく環境依存。新バージョン追従時に再評価)
    package = pkgs.mise.overrideAttrs (_: { doCheck = false; });
    enableZshIntegration = true;
    enableFishIntegration = false;
    globalConfig = {
      tools = {
        node = "22.21.0";
        python = "3.11.7";
        sbt = "1.10.2";
        helm = "3.14.0";
        terraform = "1.7.0";
        java = "temurin-25.0.0+36.0.LTS";
        "scala-cli" = "latest";
        pnpm = "latest";
        # Notion CLI (公式 ntn) - coding agent から bash 経由で叩く用
        "npm:ntn" = "latest";
      };
      settings = {
        # プロジェクトごとの.python-version, .node-versionなどを有効化
        idiomatic_version_file_enable_tools = ["python" "node" "java"];
      };
    };
  };
}
