{ config, pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    font = {
      name = "Meslo Nerd Font";
      size = 9;
    };
    themeFile = "GitHub_Dark";
    extraConfig = ''
      enable_audio_bell no
      background_opacity 1.0
      scrollback_lines 10000
      cursor_shape block
    '';
  };

  programs.bash = {
    enable = true;
    initExtra = "";
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --impure --flake /etc/nixos/";
      rehome = "home-manager switch --impure --flake ~/.home-manager/";
      pipes = "pipes-rs";
      venv = ". .venv/bin/activate";
      vim = "nvim";
    };
  };

  home.packages = with pkgs; [ pipes-rs ];

  home.file.".config/pipes-rs/config.toml".source = ~/.home-manager/config_files/pipes-rs/config.toml;
  home.file.".config/pipes-rs/config.toml".force = true;
}
