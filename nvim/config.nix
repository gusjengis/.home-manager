{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.activation.cloneNeovimConfig = lib.hm.dag.entryAfter [ "createDocumentsDirs" ] ''
    export PATH="${pkgs.git}/bin:$PATH"
    source "$HOME/.home-manager/scripts/clone-repo.sh"

    cd ~/.config/

    clone_repo https://github.com/gusjengis/nvim.git
  '';
}
