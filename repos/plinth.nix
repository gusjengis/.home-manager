{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.activation.clonePlinth = lib.hm.dag.entryAfter [ "createDocumentsDirs" ] ''
    export PATH="${pkgs.git}/bin:$PATH"
    source "$HOME/.home-manager/scripts/clone-repo.sh"

    cd ~/Documents/Code/Plinth/

    clone_repo https://github.com/gusjengis/Plinth-Core.git
    clone_repo https://github.com/gusjengis/Plinth-Util.git
    clone_repo https://github.com/gusjengis/Plinth-Web.git
    clone_repo https://github.com/gusjengis/Plinth-Web-Build.git
    clone_repo https://github.com/gusjengis/Plinth-Hello-World.git
  '';
}
