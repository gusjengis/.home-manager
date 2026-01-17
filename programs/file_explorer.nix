{
  config,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    # nautilus
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
