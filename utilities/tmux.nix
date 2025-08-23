{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{

  home.packages = with pkgs; [
    tmux
  ];

  home.activation.symlinkHyprlandConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ln -sf $HOME/.home-manager/config_files/tmux/tmux.conf $HOME/.tmux.conf
  '';
}
