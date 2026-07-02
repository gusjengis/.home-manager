{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.activation.symlink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    DESKTOP_ENV_ENABLED=${lib.boolToString config.desktopEnv.enable} bash "$HOME/.home-manager/scripts/symlink.sh"
  '';
}
