{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.activation.cloneMisc = lib.hm.dag.entryAfter [ "createDocumentsDirs" ] ''
    export PATH="${pkgs.git}/bin:$PATH"

    clone_repo() {
    	local repo_url="$1"
    	local repo_name

    	repo_name=$(basename -s .git "$repo_url")

    	if [ ! -d "$repo_name" ]; then
    	  git clone "$repo_url"
    	fi
    }

    cd ~/Documents/Code/

    clone_repo https://github.com/gusjengis/mermaid-class-diagrams.git
    clone_repo https://github.com/gusjengis/lsp-servers.git
    clone_repo https://github.com/gusjengis/lsp-servers-cli.git
    clone_repo https://github.com/gusjengis/hyprlog.git
    clone_repo https://github.com/gusjengis/Particle-Physics-Sim.git
    clone_repo https://github.com/gusjengis/Resume.git
    clone_repo https://github.com/agreenweb/timeline.git
    clone_repo https://github.com/agreenweb/cronosearch.git
    clone_repo https://github.com/gusjengis/Particle-Life.git
    clone_repo https://github.com/zed-industries/zed.git
    clone_repo https://github.com/Trevogre/logoanimation
    clone_repo https://github.com/gusjengis/WatchFace.git
    clone_repo https://github.com/gusjengis/CalendarComplication.git
    clone_repo https://github.com/gusjengis/nixpkgs

    mkdir -p ~/.config/secrets/

    cd ~/.config/secrets/
    clone_repo https://github.com/gusjengis/ssh.git
  '';
}
