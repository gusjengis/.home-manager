{
  config,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    thunar
    yazi
    tumbler
    thunar-volman
    thunar-archive-plugin
    file-roller
    gvfs
    udiskie
    kdePackages.filelight
    qimgv
    zathura
  ];
}
