{
  config,
  pkgs,
  lib,
  PC,
  ...
}:

{
  home.packages =
    with pkgs;
    [
      gurk-rs
      wireplumber
      kdePackages.xwaylandvideobridge
      signal-desktop
      presenterm
      kdePackages.kdeconnect-kde
      kdePackages.kpeople
      scrcpy
      android-tools
    ]
    ++ lib.optionals PC [
      zoom-us
      #discord-canary
      #slack
    ];
}

# Need this stuff for kdeconnect

# networking.firewall = {
#   allowedTCPPortRanges = [
#     {
#       from = 1714;
#       to = 1764;
#     }
#   ];
#   allowedUDPPortRanges = [
#     {
#       from = 1714;
#       to = 1764;
#     }
#   ];

#   # Keep your existing specific ports if needed
#   allowedTCPPorts = [
#     47984
#     47985
#     47986
#     47987
#     47988
#     47989
#     47990
#     48010
#   ];
#   allowedUDPPorts = [
#     47998
#     47999
#     48000
#     48001
#     48002
#     48003
#     48004
#     48005
#     48006
#     48007
#     48008
#     48009
#     48010
#   ];
# };
