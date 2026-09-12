import json
import tempfile
import unittest
import urllib.error
from pathlib import Path

import usage


class UsageNormalizationTests(unittest.TestCase):
    def test_claude_windows(self):
        result = usage.normalize_claude({
            "five_hour": {"utilization": 12.4, "resets_at": None},
            "seven_day": {"utilization": 67.8, "resets_at": "2026-09-12T01:00:00Z"},
        })

        self.assertEqual(result["windows"][0], {"label": "5h", "used": 12, "reset": None})
        self.assertEqual(result["windows"][1]["used"], 68)

    def test_openai_windows(self):
        result = usage.normalize_openai({
            "rate_limit": {
                "primary_window": {"used_percent": 3, "reset_at": 1789206412},
                "secondary_window": {"used_percent": 34, "reset_at": 1789483561},
            }
        })

        self.assertEqual([item["used"] for item in result["windows"]], [3, 34])
        self.assertEqual(result["windows"][0]["reset"], 1789206412)


class UnavailableTests(unittest.TestCase):
    def rate_limited(self):
        return urllib.error.HTTPError("url", 429, "Too Many Requests", {}, None)

    def test_keeps_cached_windows_and_marks_them_stale(self):
        cached = {"Claude": {"windows": [{"label": "5h", "used": 27, "reset": None}], "fetched_at": 10}}

        result = usage.unavailable("Claude", self.rate_limited(), cached)

        self.assertEqual(result["windows"][0]["used"], 27)
        self.assertEqual(result["error"], "rate limited")
        self.assertEqual(result["fetched_at"], 10)
        self.assertTrue(result["stale"])
        self.assertTrue(result["available"])

    def test_reports_no_windows_without_cache(self):
        result = usage.unavailable("Claude", self.rate_limited(), {})

        self.assertEqual(result["windows"], [])
        self.assertFalse(result["available"])


class CacheTests(unittest.TestCase):
    def test_round_trip_skips_stale_providers(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "quickshell" / "ai-usage.json"
            good = {"name": "OpenAI", "windows": [{"label": "5h", "used": 4, "reset": 1}], "fetched_at": 5}

            usage.write_cache(path, [good, {"name": "Claude", "stale": True, "windows": []}])

            self.assertEqual([entry["name"] for entry in json.loads(path.read_text())["providers"]], ["OpenAI"])
            self.assertEqual(usage.read_cache(path)["OpenAI"]["windows"][0]["used"], 4)

    def test_failing_provider_keeps_its_previous_entry(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "ai-usage.json"
            cached = {"Claude": {"name": "Claude", "windows": [{"label": "5h", "used": 27, "reset": None}]}}
            good = {"name": "OpenAI", "windows": [{"label": "5h", "used": 4, "reset": 1}], "fetched_at": 5}

            usage.write_cache(path, [good, {"name": "Claude", "stale": True, "windows": []}], cached)

            stored = usage.read_cache(path)
            self.assertEqual(stored["Claude"]["windows"][0]["used"], 27)
            self.assertEqual(stored["OpenAI"]["windows"][0]["used"], 4)

    def test_missing_cache_is_empty(self):
        self.assertEqual(usage.read_cache(Path("/nonexistent/ai-usage.json")), {})


if __name__ == "__main__":
    unittest.main()
