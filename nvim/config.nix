{ config, pkgs, lib, ... }:

{
  home.activation.cloneNeovimConfig =
    lib.hm.dag.entryAfter [ "createDocumentsDirs" ] ''
      export PATH="${pkgs.git}/bin:$PATH"

      clone_repo() {
      	local repo_url="$1"
      	local repo_name

      	repo_name=$(basename -s .git "$repo_url")

      	if [ ! -d "$repo_name" ]; then
      	  git clone "$repo_url"
      	fi
      }

      cd ~/.config/

      clone_repo https://github.com/gusjengis/nvim.git
    '';
}
