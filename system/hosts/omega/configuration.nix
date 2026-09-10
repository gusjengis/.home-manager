{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.11";
  dataDrive.client.enable = true;
  dataDrive.server.enable = false;
  git.enable = true;
  gnome.enable = false;
  grub.enable = true;
  homeAssistant.enable = false;
  hyprland.enable = false;
  joshsMass.enable = false;
  login.gnome.enable = false;
  musicAssistant.enable = false;
  nextcloud.enable = false;
  nextcloud.funnel.enable = false;
  nvidia.enable = true;
  nvim.enable = true;
  parakeetAsr.enable = false;
  repo.networkmanager.enable = true;
  tailscale.enable = true;
  vial.enable = false;
  virtual-machines.enable = false;
}
