{ config, pkgs, lib, ... }:

{
  home.activation.clonePlinth =
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

      cd ~/Documents/Code/Plinth/

      clone_repo https://github.com/gusjengis/Plinth-Core.git
      clone_repo https://github.com/gusjengis/Plinth-Util.git
      clone_repo https://github.com/gusjengis/Plinth-Web.git
      clone_repo https://github.com/gusjengis/Plinth-Web-Build.git
      clone_repo https://github.com/gusjengis/Plinth-Hello-World.git
    '';
}
