{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages =
    with pkgs;
    [
      wireplumber
    ]
    ++ lib.optionals PC [
      zoom-us
      discord-canary
    ];
}
