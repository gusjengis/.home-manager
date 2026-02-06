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
}
