{ config, pkgs, lib, ... }:

{
  home.activation.createDocumentsDirs =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ~/Documents/Code ~/Documents/Obsidian ~/Documents/Code/Mosaic ~/Documents/Code/Plinth ~/Documents/Circuits
    '';
}
