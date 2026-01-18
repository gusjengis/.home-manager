{ config, pkgs, lib, ... }:

{
  home.activation.cloneMisc = lib.hm.dag.entryAfter [ "createDocumentsDirs" ] ''
    export PATH="${pkgs.git}/bin:$PATH"

    clone_repo() {
    	local repo_url="$1"
    	local repo_name

    	repo_name=$(basename -s .git "$repo_url")

    	if [ ! -d "$repo_name" ]; then
              git clone "$repo_url" || echo "clone failed: $repo_url"
    	fi
    }

    cd ~/Documents/Code/
    clone_repo https://github.com/gusjengis/Particle-Physics-Sim.git
 '';
}
