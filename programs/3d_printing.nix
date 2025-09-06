{
  config,
  pkgs,
  PC,
  lib,
  ...
}:

{
  nixpkgs.config = {
    permittedInsecurePackages = [ "libsoup-2.74.3" ];
  };

  home.packages =
    with pkgs;
    [
    ]
    ++ lib.optionals PC [ bambu-studio ];
}
