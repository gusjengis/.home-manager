#!/usr/bin/env bash
set -euo pipefail

clock_text="$(date '+%a %d  %I:%M%P')"
clock_text="${clock_text/%m/}"

printf '{"text":"%s","tooltip":"%s"}\n' \
  "$clock_text" \
  "$(date '+%Y-%m-%d %H:%M:%S')"
