{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.activation.clonePortfolio = lib.hm.dag.entryAfter [ "createDocumentsDirs" ] ''
    export PATH="${pkgs.git}/bin:$PATH"
    source "$HOME/.home-manager/scripts/clone-repo.sh"

    cd ~/Documents/Code/

    clone_repo https://github.com/gusjengis/Portfolio.git
    clone_repo https://github.com/gusjengis/CRT.git
    clone_repo https://github.com/gusjengis/Graph.git
    clone_repo https://github.com/gusjengis/Line_Test.git
    clone_repo https://github.com/gusjengis/MinecraftDemo.git
    clone_repo https://github.com/gusjengis/Morse_Code.git
    clone_repo https://github.com/gusjengis/oscilloscope_video.git
    clone_repo https://github.com/gusjengis/Paint.git
    clone_repo https://github.com/gusjengis/pLife.git
    clone_repo https://github.com/gusjengis/Platformer.git
    clone_repo https://github.com/gusjengis/Snowflake.git
    clone_repo https://github.com/gusjengis/Synthesizer.git
    clone_repo https://github.com/gusjengis/webGL.git
    clone_repo https://github.com/gusjengis/Wireframe.git
    clone_repo https://github.com/gusjengis/WebGPU-Spiral.git
    clone_repo https://github.com/gusjengis/Perlin-Noise-Generator.git
    clone_repo https://github.com/gusjengis/Game-of-Life.git
  '';
}
