{
  config,
  pkgs,
  stable,
  PC,
  lib,
  ...
}:

{
  home.packages =
    with pkgs;
    [
      posting
      docker
      oxker
      numlockx
      openssl
      rustup
      cloc
      stable.nodejs_24
      stable.typst
      zathura
      mesa-demos
      vulkan-tools
      mermaid-cli
      stable.zed-editor
      sherlock-launcher
    ]
    ++ lib.optionals PC [
      cudaPackages.nsight_systems
      blender
      vscode
      immersed
      mutter
      arduino
      android-studio
    ];
}
# ~/.home-manager/ rehome
# warning: Git tree '/home/gusjengis/.home-manager' is dirty
# warning: Git tree '/home/gusjengis/.home-manager' is dirty
# warning: Git tree '/home/gusjengis/.home-manager' is dirty
# warning: Git tree '/home/gusjengis/.home-manager' is dirty
# error: hash mismatch in fixed-output derivation '/nix/store/i9md7xxdqz1yy8dckr792afcgsdh2ypr-source.drv':
#         specified: sha256-4cP6cohUZdhvr6mvIOozhg1ahEZEypCCjvAz0fjAtec=
#            got:    sha256-Q7Ord+GJJcOCH/S3qNwAbzILqQiIC94qb8V+JkzQqaQ=
# error: 1 dependencies of derivation '/nix/store/x27ga3pszlial5ghf4jz3v3jgrbwk15r-zed-editor-0.202.5.drv' failed to build
# error: 1 dependencies of derivation '/nix/store/4xymb2r3gi1avawxkprh20azm1lx9di9-home-manager-path.drv' failed to build
# error: 1 dependencies of derivation '/nix/store/94w80kr9l4zrn4q0s0b3xm77xrs4zj1y-home-manager-generation.drv' failed to build
