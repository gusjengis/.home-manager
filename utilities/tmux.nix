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
    fd
    skim
  ];

  home.activation.symlinkHyprlandConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/.config/tmux

    ln -sf $HOME/.home-manager/config_files/tmux/tmux.conf $HOME/.config/tmux/tmux.conf
  '';
}
