#!/usr/bin/env bash
set -euo pipefail

source "$HOME/.home-manager/scripts/clone-repo.sh"

export -f sync_repo clone_repo

declare -a REPOS=(
    "/etc/;https://github.com/gusjengis/nix-modules.git"
    "$HOME/;https://github.com/gusjengis/.home-manager.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/nix-install-script.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/Portfolio.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/CRT.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/Graph.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/Line_Test.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/MinecraftDemo.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/Morse_Code.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/oscilloscope_video.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/Paint.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/pLife.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/Platformer.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/Snowflake.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/Synthesizer.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/webGL.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/Wireframe.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/WebGPU-Spiral.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/Perlin-Noise-Generator.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/Game-of-Life.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/mermaid-class-diagrams.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/lsp-servers.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/lsp-servers-cli.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/hyprlog.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/Particle-Physics-Sim.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/Resume.git"
    "$HOME/Documents/Code/;https://github.com/agreenweb/timeline.git"
    "$HOME/Documents/Code/;https://github.com/agreenweb/cronosearch.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/Particle-Life.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/WatchFace.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/CalendarComplication.git"
    "$HOME/Documents/Code/;https://github.com/gusjengis/log_conversion_script.git"
    "$HOME/Documents/Code/AUR/;ssh://aur@aur.archlinux.org/hyprlog.git"
    "$HOME/.config/;https://github.com/gusjengis/nvim.git"
    "$HOME/.config/;https://github.com/gusjengis/secrets.git"
    "$HOME/Documents/Code/Plinth/;https://github.com/gusjengis/Plinth-Core.git"
    "$HOME/Documents/Code/Plinth/;https://github.com/gusjengis/Plinth-Util.git"
    "$HOME/Documents/Code/Plinth/;https://github.com/gusjengis/Plinth-Web.git"
    "$HOME/Documents/Code/Plinth/;https://github.com/gusjengis/Plinth-Web-Build.git"
    "$HOME/Documents/Code/Plinth/;https://github.com/gusjengis/Plinth-Hello-World.git"
    "$HOME/Documents/Code/Mosaic/;https://github.com/gusjengis/Mosaic-Backend.git"
    "$HOME/Documents/Code/Mosaic/;https://github.com/gusjengis/Mosaic-Model.git"
    "$HOME/Documents/Code/Mosaic/;https://github.com/gusjengis/Mosaic-Hub.git"
    "$HOME/Documents/Code/Mosaic/;https://github.com/gusjengis/Mosaic-Android.git"
    "$HOME/Documents/Code/Mosaic/;https://github.com/gusjengis/Mosaic-Snitch.git"
)

for item in "${REPOS[@]}"; do
    dir="${item%%;*}"
    url="${item##*;}"
    sync_repo "$dir" "$url" &
done
wait
