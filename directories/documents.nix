{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.activation.createDocumentsDirs = lib.hm.dag.entryBefore [ "syncRepos" ] ''
    mkdir -p ~/Documents/Code ~/Documents/Obsidian ~/Documents/Code/Mosaic ~/Documents/Code/Plinth ~/Documents/Code/AUR
  '';
}
