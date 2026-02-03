#!/usr/bin/env bash
set -euo pipefail

clone_repo() {
    local repo_url="$1"
    local repo_name

    repo_name=$(basename -s .git "$repo_url")

    if [ ! -d "$repo_name" ]; then
        git clone "$repo_url" || echo "clone failed: $repo_url"
    fi
}
