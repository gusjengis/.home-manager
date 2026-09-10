{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./local.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  boot.loader.efi.canTouchEfiVariables = false;
  networking.networkmanager.wifi.backend = "iwd";

  hardware.graphics = {
    enable = true;
    package = pkgs.mesa;
    extraPackages = with pkgs; [
      libgbm
      libglvnd
    ];
  };

  hardware.asahi.enable = true;

  bedtimeLockout.enable = false;

  environment.systemPackages = with pkgs; [
    iwd
  ];
  services.keyd = {
    enable = true;

    keyboards = {
      default = {
        extraConfig = ''
          [ids]
          05ac:0353:6f083222
          [main]
          capslock = overload(control, esc)
        '';
      };
    };
  };

  networking.networkmanager.wifi.powersave = false;
  system.stateVersion = "25.11"; # DO NOT CHANGE
}
