#!/usr/bin/env bash
set -euo pipefail

source "$HOME/.home-manager/scripts/clone-repo.sh"

cd ~/Documents/Code/

# Portfolio

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

# Misc

clone_repo https://github.com/gusjengis/mermaid-class-diagrams.git
clone_repo https://github.com/gusjengis/lsp-servers.git
clone_repo https://github.com/gusjengis/lsp-servers-cli.git
clone_repo https://github.com/gusjengis/hyprlog.git
clone_repo https://github.com/gusjengis/Particle-Physics-Sim.git
clone_repo https://github.com/gusjengis/Resume.git
clone_repo https://github.com/agreenweb/timeline.git
clone_repo https://github.com/agreenweb/cronosearch.git
clone_repo https://github.com/gusjengis/Particle-Life.git
clone_repo https://github.com/gusjengis/WatchFace.git
clone_repo https://github.com/gusjengis/CalendarComplication.git
clone_repo https://github.com/gusjengis/nixpkgs

clone_repo ssh://aur@aur.archlinux.org/hyprlog.git

cd ~/.config/

clone_repo https://github.com/gusjengis/secrets.git

cd ~/Documents/Code/Plinth/

clone_repo https://github.com/gusjengis/Plinth-Core.git
clone_repo https://github.com/gusjengis/Plinth-Util.git
clone_repo https://github.com/gusjengis/Plinth-Web.git
clone_repo https://github.com/gusjengis/Plinth-Web-Build.git
clone_repo https://github.com/gusjengis/Plinth-Hello-World.git

cd ~/Documents/Code/Mosaic/

clone_repo https://github.com/gusjengis/Mosaic-Backend.git
clone_repo https://github.com/gusjengis/Mosaic-Model.git
clone_repo https://github.com/gusjengis/Mosaic-Hub.git
clone_repo https://github.com/gusjengis/Mosaic-Android.git
clone_repo https://github.com/gusjengis/Mosaic-Snitch.git

printf "\r\033[K\n"
