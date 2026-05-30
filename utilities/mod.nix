{
  config,
  pkgs,
  PC,
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
      nvtopPackages.full
      zip
      p7zip
      unzip
      wget
      bat
    ]
    ++ lib.optionals PC [
      wineWow64Packages.waylandFull
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
