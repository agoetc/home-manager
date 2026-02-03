{ config, pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias  = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      nvim-treesitter.withAllGrammars
      dracula-nvim
    ];

    extraConfig = ''
      colorscheme dracula
    '';
  };
}