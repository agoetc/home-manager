{ pkgs, ... }:

{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    globalConfig = {
      tools = {
        node = "22.21.0";
        python = "3.11.7";
        sbt = "1.10.2";
        helm = "3.14.0";
        terraform = "1.7.0";
        java = "temurin-25.0.0+36.0.LTS";
      };
      settings = {
        # プロジェクトごとの.python-version, .node-versionなどを有効化
        idiomatic_version_file_enable_tools = ["python" "node" "java"];
      };
    };
  };
}
