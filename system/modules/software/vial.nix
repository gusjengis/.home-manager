{
  config,
  lib,
  ...
}:

{
  options = {
    vial.enable = lib.mkEnableOption "enables Vial udev access";
  };

  config = lib.mkIf config.vial.enable {
    services.udev.extraRules = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
    '';
  };
}
