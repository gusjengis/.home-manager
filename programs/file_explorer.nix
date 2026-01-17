{
  config,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    nautilus
    kdePackages.dolphin
    thunar
    tumbler
    thunar-volman
    thunar-archive-plugin
    file-roller
    gvfs
    qimgv
    udiskie
  ];
}
