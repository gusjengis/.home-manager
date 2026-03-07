#!/usr/bin/env bash
set -euo pipefail

printf '{"text":"%s","tooltip":"%s"}\n' \
  "$(date '+%a %b %d  %I:%M %P')" \
  "$(date '+%Y-%m-%d %H:%M:%S')"
