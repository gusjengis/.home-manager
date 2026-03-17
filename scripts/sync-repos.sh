#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_LIST_DIR="$SCRIPT_DIR/repo-lists"
SYNC_REPO_GROUPS="${SYNC_REPO_GROUPS:-core}"

source "$SCRIPT_DIR/clone-repo.sh"

if ! command -v git >/dev/null 2>&1; then
    echo "git is not installed or not on PATH."
    exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
    echo "GitHub CLI (gh) is not installed or not on PATH."
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    echo "GitHub authentication not found. Starting gh auth login..."
    gh auth login
fi

export -f sync_repo clone_repo

declare -A seen_repos=()
declare -a repos=()

add_repo_entry() {
    local entry="$1"

    if [[ -z "$entry" ]]; then
        return 0
    fi

    if [[ -z "${seen_repos[$entry]+x}" ]]; then
        repos+=("$entry")
        seen_repos["$entry"]=1
    fi
}

load_repo_group() {
    local group="$1"
    local group_file="$REPO_LIST_DIR/${group}.list"
    local line

    if [[ ! -f "$group_file" ]]; then
        echo "repo group not found: $group_file"
        return 0
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        add_repo_entry "$line"
    done < "$group_file"
}

load_repo_list_file() {
    local list_file="$1"
    local line

    [[ -f "$list_file" ]] || return 0

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        add_repo_entry "$line"
    done < "$list_file"
}

IFS=',' read -r -a selected_groups <<< "$SYNC_REPO_GROUPS"
for group in "${selected_groups[@]}"; do
    group="${group//[[:space:]]/}"
    [[ -z "$group" ]] && continue
    load_repo_group "$group"
done

load_repo_list_file "$REPO_LIST_DIR/local.list"

for item in "${repos[@]}"; do
    if [[ "$item" != *";"* ]]; then
        echo "invalid repo entry (missing ';'): $item"
        continue
    fi

    dir="${item%%;*}"
    url="${item##*;}"

    dir="${dir/#\~/$HOME}"
    dir="${dir//\$HOME/$HOME}"

    sync_repo "$dir" "$url" &
done
wait
