{
  config,
  pkgs,
  lib,
  ...
}:

{
  options = {
    login.gnome.enable = lib.mkEnableOption "enables gnome login";
  };

  config = lib.mkIf config.login.gnome.enable {
    services.displayManager.gdm.enable = true;
  };
}
