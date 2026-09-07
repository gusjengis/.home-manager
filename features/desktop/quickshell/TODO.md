# Quickshell Roadmap

## Implemented

- Local application launcher: `SUPER+SPACE`.
- Local Tailnet host picker and remote application launcher: `SUPER+CTRL+SPACE`.
- Remote desktop IDs, names, descriptions, and icons fetched over SSH; only the
  selected application runs through Waypipe. No remote Wofi or Eww menu.
- Search, click/Enter selection, Alt+Left navigation, Escape, refresh, and errors.
- Detached remote sessions survive Quickshell configuration reloads. Failure
  details appear in the launcher; private logs live in
  `~/.local/state/quickshell/remote-apps/`.

Run `rehome` with this revision on each remote machine before using its app list.
SSH must authenticate noninteractively. Host discovery includes Linux Tailnet
peers; it does not guarantee that a peer has this helper installed.

## Remaining

- Add a keybinding help menu from Hyprland's active binds and descriptions.
- Wallpapers, possibly Quickshell or Bash.
- Bar and notification UI in Quickshell. Waybar/dunst configs are removed;
  this launcher does not implement a notification server.
- Sunshine remote-access menu, if still wanted; its CLI helpers remain.
- Verify remote GUI launches between physical machines after deploying both ends.
- Handle application-specific foreground/new-instance flags where apps daemonize
  or reuse an existing remote instance. Gio D-Bus activation is disabled, but
  application-specific single-instance behavior can still bypass forwarding.
- Remote launch logs currently have no rotation.
