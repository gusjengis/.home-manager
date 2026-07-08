{ inputs, ... }:

{
  # Caveman skill suite (caveman, caveman-commit, caveman-review, ...) for
  # OpenCode. OpenCode scans ~/.config/opencode/skills recursively for
  # **/SKILL.md, so linking the whole skills dir picks up every sub-skill.
  # Update to latest: nix flake update caveman && rehome
  xdg.configFile."opencode/skills/caveman-suite".source = "${inputs.caveman}/skills";

  # Caveman's OpenCode installer makes Caveman default-on by adding this
  # always-loaded rule file. Source it from the pinned flake input instead of
  # running the installer, so the behavior is reproducible through Home Manager.
  xdg.configFile."opencode/AGENTS.md".text = ''
    <!-- caveman-begin -->
    ${builtins.readFile "${inputs.caveman}/src/rules/caveman-activate.md"}
    <!-- caveman-end -->
  '';
}
