{
  config,
  pkgs,
  lib,
  ...
}:

{
  options = {
    grub.enable = lib.mkEnableOption "enables grub";
  };

  config = lib.mkIf config.grub.enable {
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.grub.enable = true;
    boot.loader.grub.device = "nodev";
    boot.loader.grub.useOSProber = true;
    boot.loader.grub.efiSupport = true;
    boot.loader.timeout = 1;
  };
}
