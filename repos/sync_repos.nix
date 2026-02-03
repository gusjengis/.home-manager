{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.activation.syncRepos = lib.hm.dag.entryAfter [ "createDocumentsDirs" ] ''
    export PATH="${pkgs.git}/bin:$PATH"
    bash "$HOME/.home-manager/scripts/sync-repos.sh"
  '';
}
