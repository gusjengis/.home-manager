{ config, pkgs, ... }:

{
  home.packages = with pkgs; [ gh ];

  xdg.configFile."lazygit/config.yml" = {
    force = true;
    text = ''
      os:
        editPreset: nvim
    '';
  };

  programs.git = {
    enable = true;
    settings = {
      credential.helper = "store";
      user = {
        name = "gusjengis";
        email = "anthony.j.green@outlook.com";
      };
    };
    lfs.enable = true;
  };
}
