{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.chromium = {
    enable = true;
    package = pkgs.chromium;
    commandLineArgs = [
      "--ozone-platform=wayland"
      "--ignore-gpu-blocklist"
      "--hide-crash-restore-bubble"
    ];
    extensions = [
      "iobmefdldoplhmonnnkchglfdeepnfhd" # Google Search Keyboard Shortcuts
      # "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
      "jpkfgepcmmchgfbjblnodjhldacghenp" # Pie Adblock
      "ifbmcpbgkhlpfcodhjhdbllhiaomkdej" # Office - Enable Cut, Copy, and Paste
      # "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password
      # "eiimnmioipafcokbfikbljfdeojpcgbh" # BlockSite
      # "mgngbgbhliflggkamjnpdmegbkidiapm" # Remove YouTube Shorts
      # "lcpclaffcdiihapebmfgcmmplphbkjmd" # Block YouTube Feed
      # "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
    ];
  };
}
