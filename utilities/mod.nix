{
  config,
  pkgs,
  Mac,
  lib,
  ...
}:

{
  imports = [
    ./connectivity.nix
    ./git.nix
    ./screenshots.nix
    ./audio.nix
    ./disk.nix
    ./lg_tv.nix
  ];
  home.packages =
    with pkgs;
    [
      btop
      zip
      unzip
      wget
      acpi
    ]
    ++ lib.optionals config.desktopEnv.enable [
      imagemagick
      ventoy
      usbutils
    ];
}
