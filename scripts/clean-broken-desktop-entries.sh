#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-$HOME/.local/share/applications}"

broken_files=()
broken_reasons=()

is_command_available() {
    local cmd="$1"

    if [[ "$cmd" == /* ]]; then
        [[ -x "$cmd" ]]
    else
        command -v "$cmd" >/dev/null 2>&1
    fi
}

strip_desktop_field_codes() {
    local cmd="$1"

    # Remove common desktop entry field codes from Exec/TryExec lines.
    cmd="${cmd//%f/}"
    cmd="${cmd//%F/}"
    cmd="${cmd//%u/}"
    cmd="${cmd//%U/}"
    cmd="${cmd//%i/}"
    cmd="${cmd//%c/}"
    cmd="${cmd//%k/}"

    printf '%s\n' "$cmd"
}

extract_exec_command() {
    local file="$1"
    local line cmd

    line="$(grep -m1 '^TryExec=' "$file" || true)"

    if [[ -z "$line" ]]; then
        line="$(grep -m1 '^Exec=' "$file" || true)"
    fi

    [[ -n "$line" ]] || return 1

    cmd="${line#*=}"
    cmd="$(strip_desktop_field_codes "$cmd")"

    # Handle common env wrappers, such as: Exec=env FOO=bar /path/to/app
    if [[ "$cmd" == env\ * ]]; then
        cmd="${cmd#env }"

        while [[ "$cmd" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; do
            cmd="${cmd#* }"
        done
    fi

    # Avoid guessing inside arbitrary shell launchers.
    if [[ "$cmd" =~ ^(sh|bash)[[:space:]]+-c[[:space:]]+ ]]; then
        return 2
    fi

    if [[ "$cmd" =~ ^\"([^\"]+)\" ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
    elif [[ "$cmd" =~ ^\'([^\']+)\' ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
    else
        printf '%s\n' "${cmd%% *}"
    fi
}

if [[ ! -d "$APP_DIR" ]]; then
    printf 'Desktop entry directory does not exist: %s\n' "$APP_DIR" >&2
    exit 1
fi

while IFS= read -r -d '' file; do
    exec_cmd=''
    status=0
    exec_cmd="$(extract_exec_command "$file")" || status=$?

    case "$status" in
        0)
            if ! is_command_available "$exec_cmd"; then
                broken_files+=("$file")
                broken_reasons+=("$exec_cmd")
            fi
            ;;
        1|2)
            ;;
        *)
            printf 'Unexpected parse error for %s\n' "$file" >&2
            ;;
    esac
done < <(find "$APP_DIR" -maxdepth 1 -type f -name '*.desktop' -print0)

if (( ${#broken_files[@]} == 0 )); then
    printf 'No broken desktop entries found in %s\n' "$APP_DIR"
    exit 0
fi

printf 'Broken desktop entries found:\n\n'

for i in "${!broken_files[@]}"; do
    printf '%s\n' "${broken_files[$i]}"
    printf '  missing: %s\n\n' "${broken_reasons[$i]}"
done

printf 'Delete these %d desktop entries? Type yes to confirm: ' "${#broken_files[@]}"
read -r answer

if [[ "$answer" != 'yes' ]]; then
    printf 'Aborted. Nothing deleted.\n'
    exit 0
fi

for file in "${broken_files[@]}"; do
    rm -- "$file"
    printf 'Deleted: %s\n' "$file"
done
