{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  betterbird = inputs.betterbird-nix.packages.${pkgs.system}.betterbird;
in
{
  programs.thunderbird = {
    enable = config.desktopEnv.enable;
    package = betterbird;

    profiles.default = {
      isDefault = true;

      userChrome = builtins.readFile "${../.}/config_files/betterbird/userChrome.css";

      settings = {
        # UI
        "mailnews.pane_config"                     = 1;
        "mailnews.default_sort_order"              = 2;
        "mailnews.default_sort_type"               = 18;
        "mailnews.display_date_format.override"    = 2;
        "mailnews.thread_pane_column_unread"       = true;
        "mailnews.thread_pane_column_flagged"      = true;
        "mail.ui.menubar.visible"                  = true;
        "mailnews.message_display.disable_remote_image" = false;
        "mailnews.display_html.send"               = true;
        "mail.default_send_format"                 = 0;
        "mail.identity.default.compose_html"       = true;
        "mailnews.show_send_progress_mode"         = 0;
        "mail.close_message_window.on_delete"      = false;
        "mailnews.reuse_thread_window"             = true;
        "mailnews.reuse_message_window"            = false;
        "mailnews.reuse_window.message_limit"      = 10;

        # Betterbird tray / notifications
        "mail.biff.show_in_tray"                   = true;
        "mail.minimizeToTray"                      = true;
        "mail.closeToTray"                         = true;
        "mail.startupMinimized"                    = true;
        "mail.minimizeToTray.supportedDesktops"    = "kde,gnome,xfce,mate,hyprland,lxqt";

        # userChrome.css loading
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };
    };
  };

  # Betterbird needs a profiles.ini it can write to. Home Manager's Thunderbird
  # module links it into the read-only Nix store, so replace that link with a
  # writable copy of the tracked file.
  home.activation.betterbirdProfilesIni = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    rm -f "$HOME/.thunderbird/profiles.ini"
    cp "${../.}/config_files/thunderbird/profiles.ini" "$HOME/.thunderbird/profiles.ini"
    chmod u+w "$HOME/.thunderbird/profiles.ini"
  '';
  home.file.".thunderbird/profiles.ini".force = true;

  # Betterbird needs a prefs.js to recognise the profile.  Home Manager only
  # writes user.js, so we seed a minimal prefs.js once; Betterbird overwrites
  # it on first launch.
  home.activation.betterbirdProfile = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    prefs="$HOME/.thunderbird/default/prefs.js"
    if [ ! -f "$prefs" ]; then
      mkdir -p "$(dirname "$prefs")"
      cat > "$prefs" << 'PREFS'
user_pref("mail.startup.enabledMailCheckOnce", true);
user_pref("mail.server.default.check_new_mail", false);
PREFS
    fi
  '';
}
