{
  config,
  pkgs,
  PC,
  lib,
  stable,
  ...
}:

{
  nixpkgs.config = {
    permittedInsecurePackages = [
      "libsoup-2.74.3"
      "mbedtls-2.28.10" # not sure what program needs this
    ];
  };

  # home.packages =
  #   with pkgs;
  #   [
  #   ]
  #   ++ lib.optionals PC [ stable.bambu-studio ];

}
