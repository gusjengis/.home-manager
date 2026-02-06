{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.activation.symlink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    bash "$HOME/.home-manager/scripts/symlink.sh"
  '';
}
