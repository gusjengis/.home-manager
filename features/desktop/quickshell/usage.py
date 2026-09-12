#!/usr/bin/env python3
"""Fetch subscription usage without exposing locally stored OAuth credentials."""

import json
import os
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path


TIMEOUT = 10


def read_json(path):
    with path.open(encoding="utf-8") as file:
        return json.load(file)


def cache_path(home):
    state_home = Path(os.environ.get("XDG_STATE_HOME", home / ".local" / "state"))
    return state_home / "quickshell" / "ai-usage.json"


def read_cache(path):
    try:
        return {entry["name"]: entry for entry in read_json(path)["providers"]}
    except (KeyError, OSError, TypeError, ValueError):
        return {}


def write_cache(path, providers, cached=None):
    # Only successful fetches are cached, so a failing provider keeps the last
    # numbers it managed to report instead of falling back to zeros. Merging
    # matters: a provider failing this round must not be dropped just because
    # another provider succeeded.
    merged = dict(cached or {})
    for provider in providers:
        if not provider.get("stale"):
            merged[provider["name"]] = provider

    fresh = list(merged.values())
    if not fresh:
        return
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        temporary = path.with_suffix(".tmp")
        with temporary.open("w", encoding="utf-8") as file:
            json.dump({"providers": fresh}, file, separators=(",", ":"))
        temporary.replace(path)
    except OSError:
        pass


def request_json(url, headers):
    request = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
        return json.load(response)


def window(label, value, reset):
    return {
        "label": label,
        "used": round(float(value or 0)),
        "reset": reset,
    }


def fresh(provider):
    provider["fetched_at"] = int(time.time())
    return provider


def normalize_claude(data):
    return {
        "name": "Claude",
        "available": True,
        "windows": [
            window("5h", data.get("five_hour", {}).get("utilization"), data.get("five_hour", {}).get("resets_at")),
            window("7d", data.get("seven_day", {}).get("utilization"), data.get("seven_day", {}).get("resets_at")),
        ],
    }


def normalize_openai(data):
    limits = data.get("rate_limit") or {}
    primary = limits.get("primary_window") or {}
    secondary = limits.get("secondary_window") or {}
    return {
        "name": "OpenAI",
        "available": True,
        "windows": [
            window("5h", primary.get("used_percent"), primary.get("reset_at")),
            window("7d", secondary.get("used_percent"), secondary.get("reset_at")),
        ],
    }


def unavailable(name, error, cached=None):
    if isinstance(error, urllib.error.HTTPError):
        reason = "rate limited" if error.code == 429 else f"HTTP {error.code}"
    elif isinstance(error, FileNotFoundError):
        reason = "not logged in"
    else:
        reason = "request failed"

    previous = (cached or {}).get(name) or {}
    return {
        "name": name,
        "available": bool(previous.get("windows")),
        "stale": True,
        "error": reason,
        "windows": previous.get("windows", []),
        "fetched_at": previous.get("fetched_at"),
    }


def fetch_claude(home, cached):
    try:
        auth = read_json(home / ".claude" / ".credentials.json")["claudeAiOauth"]
        data = request_json(
            "https://api.anthropic.com/api/oauth/usage",
            {
                "Authorization": f"Bearer {auth['accessToken']}",
                "anthropic-beta": "oauth-2025-04-20",
                "User-Agent": "quickshell-ai-usage/1",
            },
        )
        return fresh(normalize_claude(data))
    except (KeyError, OSError, ValueError, urllib.error.URLError) as error:
        return unavailable("Claude", error, cached)


def fetch_openai(home, cached):
    try:
        data_home = Path(os.environ.get("XDG_DATA_HOME", home / ".local" / "share"))
        auth = read_json(data_home / "opencode" / "auth.json")["openai"]
        data = request_json(
            "https://chatgpt.com/backend-api/wham/usage",
            {
                "Authorization": f"Bearer {auth['access']}",
                "ChatGPT-Account-Id": auth["accountId"],
                "User-Agent": "quickshell-ai-usage/1",
            },
        )
        return fresh(normalize_openai(data))
    except (KeyError, OSError, ValueError, urllib.error.URLError) as error:
        return unavailable("OpenAI", error, cached)


def main():
    home = Path.home()
    path = cache_path(home)
    cached = read_cache(path)

    with ThreadPoolExecutor(max_workers=2) as pool:
        providers = list(pool.map(lambda function: function(home, cached), (fetch_claude, fetch_openai)))

    write_cache(path, providers, cached)
    json.dump({"providers": providers}, sys.stdout, separators=(",", ":"))
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
