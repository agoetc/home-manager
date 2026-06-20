{ pkgs, ... }:

{
  programs.mise = {
    enable = true;
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
        "github:endevco/aube" = "latest";
        # Notion CLI (公式 ntn) - coding agent から bash 経由で叩く用
        "npm:ntn" = "latest";
        # headroom: AI エージェントのコンテキスト圧縮 (clauded alias で wrap)
        # extras は wrap/proxy 用途に必要なものに限定 (all は torch 等で激重)
        "pipx:headroom-ai" = { version = "latest"; extras = "proxy,code,memory,mcp"; };
      };
      settings = {
        # プロジェクトごとの.python-version, .node-versionなどを有効化
        idiomatic_version_file_enable_tools = ["python" "node" "java"];
      };
    };
  };
}
