{ ... }:

{
  imports = [
    ./programs/blackhole/default.nix
  ];

  # nix-darwin の状態バージョン
  system.stateVersion = 5;

  # ユーザー固有オプションの基準ユーザー
  system.primaryUser = "takegawa";

  # 標準 nix (DeterminateSystems nix-installer 由来、determinate-nixd 不使用) のため
  # nix-darwin に nix 管理を任せる (デフォルト true)。/etc の nix sourcing も維持される。
  nix.enable = true;

  # /nix/store が肥大化しないよう古い世代を自動 GC (毎週日曜 3 時、14 日より古い世代を削除)。
  nix.gc = {
    automatic = true;
    interval = { Weekday = 0; Hour = 3; Minute = 0; };
    options = "--delete-older-than 14d";
  };

  # store 内の同一ファイルをハードリンク化して容量を節約。
  nix.optimise.automatic = true;

  # 既存 nix インストールの nixbld グループ GID は 30000 (nix-darwin の既定 350 と異なる)。
  # 実値に合わせて衝突を回避する。
  ids.gids.nixbld = 30000;
}
