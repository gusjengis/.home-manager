{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    #!mac    unityhub
    #!mac    plasticscm
    # verco
  ];
}
