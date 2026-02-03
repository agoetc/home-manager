{ config, pkgs, ... }:

let
  gwq = pkgs.callPackage ./package.nix { };
in
{
  home.packages = [ gwq ];

  # gwq設定ファイル (~/.config/gwq/config.toml)
  xdg.configFile."gwq/config.toml".text = ''
    [finder]
    preview = true

    [naming]
    # ghqと同じ形式: Host/Owner/Repo/Branch
    template = '{{.Host}}/{{.Owner}}/{{.Repository}}/{{.Branch}}'

    [naming.sanitize_chars]
    '/' = '-'
    ':' = '-'

    [ui]
    icons = true
    tilde_home = true

    [worktree]
    auto_mkdir = true
    # ghqのrootと同じ場所に配置
    basedir = '~/Work'
  '';
}
