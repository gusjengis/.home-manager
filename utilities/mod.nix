{
  config,
  pkgs,
  Mac,
  lib,
  ...
}:

{
  imports = [
    ./bluetooth.nix
    ./git.nix
    ./screenshots.nix
    ./audio.nix
    ./disk.nix
    ./lg_tv.nix
    ./tmux.nix
  ];
  home.packages =
    with pkgs;
    [
      btop
      zip
      usbutils
    ]
    ++ lib.optionals Mac [ acpi ];
}
