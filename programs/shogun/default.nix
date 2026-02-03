{ config, pkgs, lib, ... }:

let
  shogunDir = "${config.home.homeDirectory}/.local/share/multi-agent-shogun";
in
{
  home.activation.shogunSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "${shogunDir}" ]; then
      ${pkgs.git}/bin/git clone https://github.com/yohey-w/multi-agent-shogun.git "${shogunDir}"
    else
      ${pkgs.git}/bin/git -C "${shogunDir}" pull --ff-only || true
    fi
    chmod +x "${shogunDir}/shutsujin_departure.sh" 2>/dev/null || true
    chmod +x "${shogunDir}/first_setup.sh" 2>/dev/null || true
  '';

  programs.zsh.shellAliases = {
    shogun = "${shogunDir}/shutsujin_departure.sh";
    css = "tmux attach-session -t shogun";
    csm = "tmux attach-session -t multiagent";
  };
}
