{ config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    # 将来削除されるデフォルト値に依存しない
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        identityAgent = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
      };
    };
  };
}
