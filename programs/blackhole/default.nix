{ pkgs, ... }:

let
  # nixpkgs 版 BlackHole 0.6.1 (2ch)。
  # NOTE: このパッケージの `channel` override は内部 bundleID / channel 数を実際には
  # 変えられず (GCC_PREPROCESSOR_DEFINITIONS が効かない)、2ch 以外を共存させると
  # 内部 bundleID `audio.existential.BlackHole2ch` が衝突して片方しか coreaudiod に
  # 読まれない。よって 2ch のみ導入する。
  bh2 = pkgs.blackhole.override { channel = "2ch"; };
  halDir = "/Library/Audio/Plug-Ins/HAL";
in
{
  # HAL ドライバはシステム領域 (要 root) に実体配置しないと coreaudiod が読まないため、
  # activation script で nix store から /Library/Audio/Plug-Ins/HAL/ へコピーする。
  # (symlink だと coreaudiod / コード署名で不安定なため実体コピー)
  system.activationScripts.postActivation.text = ''
    echo "[blackhole] installing BlackHole 2ch (0.6.1) to ${halDir}" >&2

    # 旧バージョン (手動インストール v0.5.0 / 不要になった 16ch) のバンドルを除去。
    # 大文字/小文字綴り差 (BlackHole/Blackhole) で二重登録になるのを防ぐ。
    for name in BlackHole2ch Blackhole2ch BlackHole16ch Blackhole16ch; do
      if [ -e "${halDir}/$name.driver" ]; then
        rm -rf "${halDir}/$name.driver"
      fi
    done

    cp -R "${bh2}/Library/Audio/Plug-Ins/HAL/Blackhole2ch.driver" "${halDir}/"

    # nix store のコピーは読み取り専用なので、再実行時の rm/更新のため書き込み権限を付与
    chmod -R u+w "${halDir}/Blackhole2ch.driver"

    # coreaudiod を再起動してドライバを再読込 (再生中の音が一瞬切れる)
    killall coreaudiod || true
  '';
}
