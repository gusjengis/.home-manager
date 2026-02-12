{
  config,
  pkgs,
  old,
  lib,
  PC,
  ...
}:

let
  chromiumPkg =
    if PC then
      (old.chromium.override { enableWideVine = true; })
    else
      (pkgs.chromium.override { enableWideVine = true; });
in
{
  programs.chromium = {
    enable = true;
    package = chromiumPkg;
    commandLineArgs = [
      "--ozone-platform=wayland"
      "--ignore-gpu-blocklist"
      "--hide-crash-restore-bubble"
      # "--enable-unsafe-webgpu"
    ];
    extensions = [
      "iobmefdldoplhmonnnkchglfdeepnfhd" # Google Search Keyboard Shortcuts
      "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
      "jpkfgepcmmchgfbjblnodjhldacghenp" # Pie Adblock
      "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password
      "eiimnmioipafcokbfikbljfdeojpcgbh" # BlockSite
      "mgngbgbhliflggkamjnpdmegbkidiapm" # Remove YouTube Shorts
      "lcpclaffcdiihapebmfgcmmplphbkjmd" # Block YouTube Feed
      "ifbmcpbgkhlpfcodhjhdbllhiaomkdej" # Office - Enable Cut, Copy, and Paste
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
    ];
  };
}
