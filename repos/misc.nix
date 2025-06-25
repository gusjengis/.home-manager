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
  '';
}

# clone_repo https://github.com/gusjengis/neovim-project.git
