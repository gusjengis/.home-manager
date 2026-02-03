{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.activation.cloneMosaic = lib.hm.dag.entryAfter [ "createDocumentsDirs" ] ''
    export PATH="${pkgs.git}/bin:$PATH"
    source "$HOME/.home-manager/scripts/clone-repo.sh"

    cd ~/Documents/Code/Mosaic/

    clone_repo https://github.com/gusjengis/Mosaic-Backend.git
    clone_repo https://github.com/gusjengis/Mosaic-Model.git
    clone_repo https://github.com/gusjengis/Mosaic-Hub.git
    clone_repo https://github.com/gusjengis/Mosaic-Android.git
    clone_repo https://github.com/gusjengis/Mosaic-Snitch.git
  '';
}
