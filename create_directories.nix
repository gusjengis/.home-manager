{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.activation.createDirs = lib.hm.dag.entryBefore [ "syncRepos" ] ''
    mkdir -p  ~/Documents/Obsidian  ~/Documents/Code/AUR
  '';
}
