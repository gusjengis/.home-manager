{ config, pkgs, lib, ... }:

{
  home.activation.cloneMosaic =
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

      cd ~/Documents/Code/Mosaic/

      clone_repo https://github.com/gusjengis/Mosaic-Backend.git
      clone_repo https://github.com/gusjengis/Mosaic-Model.git
      clone_repo https://github.com/gusjengis/Mosaic-Hub.git
      clone_repo https://github.com/gusjengis/Mosaic-Android.git
      clone_repo https://github.com/gusjengis/Mosaic-Logger-Hyprland.git
      clone_repo https://github.com/gusjengis/Mosaic-Snitch.git
      clone_repo https://github.com/gusjengis/Mosaic-Docs.git
    '';
}
