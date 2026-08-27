#!/usr/bin/env bash
set -euo pipefail

# sync-mail-filters.sh - bidirectional sync of Thunderbird filter files.
#
# Usage:
#   sync-mail-filters.sh save   - copy profile filters to repo (run before rebuild)
#   sync-mail-filters.sh load   - copy repo filters to profile (after rebuild)

REPO="$HOME/.home-manager/config_files/betterbird/filters"
PROFILE="$HOME/.thunderbird/default/ImapMail"

# Manually created Thunderbird accounts use these ImapMail subdirectories.
declare -A DIRS=(
  [work]="outlook.office365.com"
  [outlook]="outlook.office365-1.com"
  [gmail]="imap.gmail.com"
)

cmd="${1:-save}"

case "$cmd" in
  save)
    for acct in "${!DIRS[@]}"; do
      src="$PROFILE/${DIRS[$acct]}/msgFilterRules.dat"
      dst="$REPO/${acct}.dat"
      if [ -f "$src" ]; then
        cp "$src" "$dst"
        echo "saved: $acct"
      fi
    done
    ;;
  load)
    for acct in "${!DIRS[@]}"; do
      src="$REPO/${acct}.dat"
      dst="$PROFILE/${DIRS[$acct]}/msgFilterRules.dat"
      if [ -f "$src" ]; then
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        echo "loaded: $acct"
      fi
    done
    ;;
  *)
    echo "usage: $0 [save|load]" >&2
    exit 1
    ;;
esac
