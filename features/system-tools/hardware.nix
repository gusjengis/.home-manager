{
  config,
  pkgs,
  PC,
  lib,
  ...
}:

{
  home.packages =
    lib.optionals PC [ pkgs.wineWow64Packages.waylandFull ]
    ++ lib.optionals config.desktopEnv.enable [
      pkgs.ventoy
      pkgs.usbutils
    ]
    ++ lib.optionals config.laptop.enable [ pkgs.acpi ];
}
