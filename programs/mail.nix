{
  config,
  pkgs,
  lib,
  ...
}:
lib.mkIf config.desktopEnv.enable {
  programs.thunderbird = {
    enable = config.desktopEnv.enable;
    package = pkgs.thunderbird;

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

        # Notifications
        "mail.biff.show_alert"                     = true;
        "mail.biff.use_system_alert"               = true;

        # userChrome.css loading
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };
    };
  };

  # Thunderbird needs a writable profiles.ini. Replace Home Manager's store
  # link with a writable copy of the tracked file.
  home.activation.thunderbirdProfilesIni = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    rm -f "$HOME/.thunderbird/profiles.ini"
    cp "${../.}/config_files/thunderbird/profiles.ini" "$HOME/.thunderbird/profiles.ini"
    chmod u+w "$HOME/.thunderbird/profiles.ini"
  '';
  home.file.".thunderbird/profiles.ini".force = true;

  # Seed prefs.js so Thunderbird recognises the Home Manager profile.
  home.activation.thunderbirdProfile = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
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
