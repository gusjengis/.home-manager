#!/usr/bin/env bash
set -euo pipefail

sel_file="${1:-}"
cfg_dir="${2:-}"
host="${3:-}"

if [[ -z "${sel_file// }" || -z "${cfg_dir// }" || -z "${host// }" ]]; then
  exit 1
fi

mkdir -p "$(dirname "$sel_file")"
printf '%s\n' "$host" >"$sel_file"

if command -v eww >/dev/null 2>&1; then
  eww --config "$cfg_dir" close waypipe-hosts >/dev/null 2>&1 || true
fi
