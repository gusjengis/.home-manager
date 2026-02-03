{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.activation.cloneMisc = lib.hm.dag.entryAfter [ "createDocumentsDirs" ] ''
    export PATH="${pkgs.git}/bin:$PATH"
    source "$HOME/.home-manager/scripts/clone-repo.sh"

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
    clone_repo https://github.com/gusjengis/WatchFace.git
    clone_repo https://github.com/gusjengis/CalendarComplication.git
    clone_repo https://github.com/gusjengis/nixpkgs

    clone_repo ssh://aur@aur.archlinux.org/hyprlog.git


    cd ~/.config/
    clone_repo https://github.com/gusjengis/secrets.git
  '';
}
