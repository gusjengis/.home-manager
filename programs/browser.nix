{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.chromium = {
    enable = true;
    commandLineArgs = [
      "--ozone-platform=x11"
      # "--enable-unsafe-webgpu"
      # "--enable-features=Vulkan"
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
