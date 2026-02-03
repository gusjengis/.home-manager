#!/usr/bin/env bash
set -euo pipefail

clone_repo() {
    local repo_url="$1"
    local repo_name

    repo_name=$(basename -s .git "$repo_url")

    if [ ! -d "$repo_name" ]; then
        git clone "$repo_url" 2>/dev/null || { echo "clone failed: $repo_url"; return 0; }
    else
        if ! git -C "$repo_name" rev-parse --git-dir >/dev/null 2>&1; then
            echo "$repo_name: not a valid git repository - removing and re-cloning"
            rm -rf "$repo_name"
            git clone "$repo_url" 2>/dev/null || { echo "clone failed: $repo_url"; return 0; }
            return 0
        fi

        (
            set +e
            cd "$repo_name" 2>/dev/null || { echo "cd failed: $repo_name"; return 0; }

            if [ -n "$(git status --porcelain)" ]; then
                echo "skipping sync for $repo_name: has uncommitted changes"
                return 0
            fi

            git fetch origin 2>/dev/null || { echo "fetch failed: $repo_name"; return 0; }

            local local_rev remote_rev
            local_rev=$(git rev-parse HEAD 2>/dev/null || echo "")
            remote_rev=$(git rev-parse "@{u}" 2>/dev/null || echo "")

            if [ -z "$remote_rev" ]; then
                echo "$repo_name: no upstream branch configured"
                return 0
            fi

            if [ "$local_rev" != "$remote_rev" ]; then
                git pull --ff-only -q 2>/dev/null || {
                    local pull_result=$?
                    if [ $pull_result -eq 128 ]; then
                        echo "$repo_name: pull would merge (not fast-forward) - manual resolution needed"
                    else
                        echo "pull failed: $repo_name"
                    fi
                    return 0
                }
            fi
        )
    fi
}

sync_repo() {
    local dir="$1"
    local repo_url="$2"

    mkdir -p "$dir"

    (
        cd "$dir" 2>/dev/null || { echo "cd failed: $dir"; return 0; }
        clone_repo "$repo_url"
    ) | sed 's/^/\x1b[31m/;s/$/\x1b[0m/'
}
