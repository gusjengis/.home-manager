#!/usr/bin/env bash
set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1; }

# ---------- data ----------
get_status() {
  local now_line1 now_line2
  now_line1=$(date "+%A, %B %d")
  now_line2=$(date "+%I:%M:%S %p")

  local bat_raw bat_pct bat_state bat_time
  bat_raw="$(acpi -b 2>/dev/null | head -n1 || true)"

  bat_pct=-1
  bat_state="Unknown"
  bat_time="N/A"

  if [[ -n "$bat_raw" ]]; then
    local pct_str
    pct_str="$(grep -oP '\d+%' <<<"$bat_raw" | head -n1 || true)"
    [[ -n "$pct_str" ]] && bat_pct="${pct_str%\%}"
    bat_state="$(awk -F', ' '{print $1}' <<<"$bat_raw" | awk '{print $3}' || echo "Unknown")"

    if grep -qE '[0-9]{2}:[0-9]{2}:[0-9]{2}' <<<"$bat_raw"; then
      local hhmmss h m
      hhmmss="$(grep -oE '[0-9]{2}:[0-9]{2}:[0-9]{2}' <<<"$bat_raw" | head -n1)"
      h="${hhmmss:0:2}"; m="${hhmmss:3:2}"
      h=$((10#$h)); m=$((10#$m))
      if (( h > 0 )); then bat_time="${h}h ${m}m"; else bat_time="${m}m"; fi
    fi
  fi

  local wifi_line ssid signal
  wifi_line="Wi-Fi: N/A"
  if have nmcli; then
    ssid="$(nmcli -t -f ACTIVE,TYPE,NAME con show 2>/dev/null | awk -F: '$1=="yes" && $2=="wifi"{print $3; exit}')"
    signal="$(nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | awk -F: '$1=="*"{print $2; exit}')"
    if [[ -n "${ssid:-}" ]]; then
      if [[ -n "${signal:-}" ]]; then wifi_line="Wi-Fi: ${ssid} (${signal}%)"
      else wifi_line="Wi-Fi: ${ssid}"
      fi
    fi
  elif have iwgetid; then
    ssid="$(iwgetid -r 2>/dev/null || true)"
    [[ -n "$ssid" ]] && wifi_line="Wi-Fi: ${ssid}"
  fi

  printf '%s\n' "$now_line1" "$now_line2" "$bat_pct" "$bat_state" "$bat_time" "$wifi_line"
}

# ---------- ANSI helpers ----------
RESET=$'\033[0m'
FG_TEXT=$'\033[38;5;255m'

# Background colors (ANSI 256)
BG_RED=$'\033[48;5;196m'
BG_ORANGE=$'\033[48;5;208m'
BG_YELLOW=$'\033[48;5;226m'
BG_GREEN=$'\033[48;5;46m'
BG_EMPTY=$'\033[48;5;236m'   # dark gray for empty segments

bar_bg_for_pct() {
  local p="$1"
  if (( p < 0 )); then
    printf '%s' "$BG_EMPTY"
  elif (( p <= 15 )); then
    printf '%s' "$BG_RED"
  elif (( p <= 35 )); then
    printf '%s' "$BG_ORANGE"
  elif (( p <= 60 )); then
    printf '%s' "$BG_YELLOW"
  else
    printf '%s' "$BG_GREEN"
  fi
}

# ---------- render ----------
repeat_char() {
  local ch="$1" count="$2"
  printf "%*s" "$count" "" | tr ' ' "$ch"
}

draw() {
  local now1="$1" now2="$2" pct="$3" state="$4" est="$5" wifi="$6"

  local rows cols
  rows=$(tput lines)
  cols=$(tput cols)

  # You can tune these:
  local segments=18      # number of blocks
  local seg_w=2          # width of each block (characters)
  local gap_w=1          # gap between blocks (spaces)
  local pad=1            # inner padding between border and segments

  # Compute bar width: borders + padding + segments + gaps
  local seg_total=$(( segments * seg_w ))
  local gaps_total=$(( (segments - 1) * gap_w ))
  local inner_w=$(( pad + seg_total + gaps_total + pad ))
  local bar_w=$(( inner_w + 2 )) # add border sides

  # Center block vertically with some header/footer lines
  local header1="System Status"
  local header2="$now1  •  $now2"

  local header3
  if (( pct >= 0 )); then
    header3="Battery: ${pct}% (${state})  •  Estimate: ${est}"
  else
    header3="Battery: N/A"
  fi

  local block_h=7  # header(3) + blank + borders(3)
  local top=$(( (rows - block_h) / 2 ))
  (( top < 0 )) && top=0
  local left=$(( (cols - bar_w) / 2 ))
  (( left < 0 )) && left=0

  # Determine how many segments are filled
  local filled=0
  if (( pct >= 0 )); then
    # round to nearest segment
    filled=$(( (pct * segments + 50) / 100 ))
    (( filled < 0 )) && filled=0
    (( filled > segments )) && filled=$segments
  fi

  local fill_bg
  fill_bg="$(bar_bg_for_pct "$pct")"

  # Build border lines
  local top_border="┌$(repeat_char "─" $((bar_w-2)))┐"
  local bot_border="└$(repeat_char "─" $((bar_w-2)))┘"

  # Clear screen
  printf '\033[2J\033[H'

  # Print headers centered
  tput cup "$top" 0
  printf "%*s%s%s%s\n" $(( (cols - ${#header1})/2 )) "" "$FG_TEXT" "$header1" "$RESET"
  printf "%*s%s%s%s\n" $(( (cols - ${#header2})/2 )) "" "$FG_TEXT" "$header2" "$RESET"
  printf "%*s%s%s%s\n" $(( (cols - ${#header3})/2 )) "" "$FG_TEXT" "$header3" "$RESET"

  # One blank line
  printf "\n"

  # Borders + bar line
  tput cup $((top + 4)) "$left"
  printf "%s\n" "$top_border"

  # Bar line:
  # Left border
  tput cup $((top + 5)) "$left"
  printf "│"
  # Left padding
  printf "%*s" "$pad" ""

  for ((i=1; i<=segments; i++)); do
    if (( i <= filled )); then
      printf "%s%*s%s" "$fill_bg" "$seg_w" "" "$RESET"
    else
      printf "%s%*s%s" "$BG_EMPTY" "$seg_w" "" "$RESET"
    fi

    # gap (plain space so you see separation)
    if (( i < segments )); then
      printf "%*s" "$gap_w" ""
    fi
  done

  # Right padding + right border
  printf "%*s│\n" "$pad" ""

  tput cup $((top + 6)) "$left"
  printf "%s\n" "$bot_border"

  # Footer under bar (wifi + hint)
  local footer1="$wifi"
  local footer2="(press any key to close)"
  tput cup $((top + 7)) 0
  printf "%*s%s%s%s\n" $(( (cols - ${#footer1})/2 )) "" "$FG_TEXT" "$footer1" "$RESET"
  printf "%*s%s%s%s\n" $(( (cols - ${#footer2})/2 )) "" "$FG_TEXT" "$footer2" "$RESET"
}

# ---------- terminal mode + key-to-exit ----------
OLD_STTY="$(stty -g 2>/dev/null || true)"

cleanup() {
  tput cnorm 2>/dev/null || true
  [[ -n "${OLD_STTY:-}" ]] && stty "$OLD_STTY" 2>/dev/null || true
  printf '%s' "$RESET"
}
trap cleanup EXIT

tput civis 2>/dev/null || true
stty -echo -icanon min 1 time 0 2>/dev/null || true

MAIN_PID="$$"
(
  IFS= read -rsn1 _
  kill -TERM "$MAIN_PID" 2>/dev/null || true
) &

while true; do
  mapfile -t S < <(get_status)
  draw "${S[0]}" "${S[1]}" "${S[2]}" "${S[3]}" "${S[4]}" "${S[5]}"
  sleep 1
done
