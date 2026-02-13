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
  ];
  home.packages =
    with pkgs;
    [
      btop
      zip
      unzip
      wget
    ]
    ++ lib.optionals config.desktopEnv.enable [
      imagemagick
      ventoy
      usbutils
    ]
    ++ lib.optionals config.laptop.enable [
      acpi
    ];

}
