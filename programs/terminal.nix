{ config, pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    font = {
      name = "MesloLGS Nerd Font";
      size = 9;
      # name = "GohuFont 14 Nerd Font Mono";
      # size = 10.5;
    };
    themeFile = "GitHub_Dark";
    extraConfig = ''
      enable_audio_bell no
      background_opacity 1.0
      scrollback_lines 10000
      cursor_shape block
    '';
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    TERMINAL = "kitty";
  };

  home.sessionPath = [ "${config.home.homeDirectory}/.cargo/bin" ];

  programs.bash = {
    enable = true;
    initExtra = "";
    bashrcExtra = ''export PATH="$HOME/.cargo/bin:$PATH"'';
    profileExtra = ''export PATH="$HOME/.cargo/bin:$PATH"'';
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --impure --flake /etc/nixos/";
      rehome = "home-manager switch --impure --flake ~/.home-manager/";
      pipes = "pipes-rs";
      venv = ". .venv/bin/activate";
      vim = "nvim";
    };
  };

  systemd.user.sessionVariables.PATH = "$HOME/.cargo/bin:$PATH";

  home.packages = with pkgs; [ pipes-rs ];

  home.file.".config/pipes-rs/config.toml".source = ~/.home-manager/config_files/pipes-rs/config.toml;
  home.file.".config/pipes-rs/config.toml".force = true;
}
