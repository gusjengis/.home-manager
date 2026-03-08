#!/usr/bin/env python3
import json
import os
import sys
from dataclasses import dataclass
from datetime import date, datetime, time, timedelta, timezone, tzinfo
from pathlib import Path
from typing import Any
from zoneinfo import ZoneInfo

from google.oauth2 import service_account
from googleapiclient.discovery import build


DEFAULT_KEY_PATH = Path.home() / ".config/secrets/api_keys/google-calendar-service-account.json"
DEFAULT_CALENDAR_IDS_PATH = Path.home() / ".config/secrets/api_keys/google-calendar-calendar-ids.json"
DEFAULT_CACHE_DIR = Path.home() / ".cache/eww-calendar"
DEFAULT_WIDTH = 960
DEFAULT_HEIGHT = 22
DEFAULT_TIMEZONE = os.environ.get("CALENDAR_TIMELINE_TIMEZONE")


@dataclass
class EventBlock:
    calendar_name: str
    title: str
    start: datetime
    end: datetime
    color: str
    all_day: bool
    has_custom_color: bool


def local_timezone() -> ZoneInfo | tzinfo:
    if DEFAULT_TIMEZONE:
        return ZoneInfo(DEFAULT_TIMEZONE)
    return datetime.now().astimezone().tzinfo or timezone.utc


def day_bounds(tz: ZoneInfo | tzinfo) -> tuple[datetime, datetime]:
    today = datetime.now(tz).date()
    start = datetime.combine(today, time.min, tzinfo=tz)
    end = start + timedelta(days=1)
    return start, end


def rfc3339(value: datetime) -> str:
    return value.isoformat()


def parse_event_time(raw: dict[str, Any], tz: ZoneInfo | tzinfo) -> tuple[datetime, bool]:
    if "dateTime" in raw:
        return datetime.fromisoformat(raw["dateTime"].replace("Z", "+00:00")).astimezone(tz), False

    day = date.fromisoformat(raw["date"])
    return datetime.combine(day, time.min, tzinfo=tz), True


def clip_event(start: datetime, end: datetime, window_start: datetime, window_end: datetime) -> tuple[datetime, datetime] | None:
    clipped_start = max(start, window_start)
    clipped_end = min(end, window_end)
    if clipped_end <= clipped_start:
        return None
    return clipped_start, clipped_end


def sanitize_color(color: str | None) -> str:
    if not color:
        return "#5f6368"
    color = color.strip()
    if len(color) == 7 and color.startswith("#"):
        return color
    return "#5f6368"


def hex_to_rgb(color: str) -> tuple[int, int, int]:
    color = sanitize_color(color)
    return int(color[1:3], 16), int(color[3:5], 16), int(color[5:7], 16)


def rgb_to_hex(rgb: tuple[int, int, int]) -> str:
    r, g, b = rgb
    return f"#{r:02x}{g:02x}{b:02x}"


def mix_colors(base: str, target: str, ratio: float) -> str:
    ratio = max(0.0, min(1.0, ratio))
    br, bg, bb = hex_to_rgb(base)
    tr, tg, tb = hex_to_rgb(target)
    return rgb_to_hex(
        (
            round(br + (tr - br) * ratio),
            round(bg + (tg - bg) * ratio),
            round(bb + (tb - bb) * ratio),
        )
    )


def brighten_for_dark_bg(color: str) -> str:
    r, g, b = hex_to_rgb(color)
    luminance = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
    if luminance < 0.52:
        return mix_colors(color, "#ffffff", 0.28)
    return color


def fmt_time(value: datetime, all_day: bool) -> str:
    if all_day:
        return "all day"
    return value.strftime("%H:%M")


def build_tooltip(events: list[EventBlock]) -> str:
    if not events:
        return "No calendar events today"

    lines = []
    for event in events:
        lines.append(
            f"{fmt_time(event.start, event.all_day)} - {fmt_time(event.end, event.all_day)}  {event.title} [{event.calendar_name}]"
        )
    return "\n".join(lines)


def load_configured_calendar_ids() -> list[str]:
    env_value = os.environ.get("CALENDAR_TIMELINE_CALENDAR_IDS", "").strip()
    if env_value:
        return [item.strip() for item in env_value.split(",") if item.strip()]

    ids_path = Path(os.environ.get("CALENDAR_TIMELINE_CALENDAR_IDS_FILE", DEFAULT_CALENDAR_IDS_PATH))
    if not ids_path.exists():
        return []

    payload = json.loads(ids_path.read_text(encoding="utf-8"))
    if isinstance(payload, dict):
        payload = payload.get("calendar_ids", [])

    if not isinstance(payload, list):
        raise ValueError(f"Calendar ID config at {ids_path} must be a JSON list or an object with calendar_ids")

    return [str(item).strip() for item in payload if str(item).strip()]


def discover_calendars(service: Any) -> list[dict[str, str]]:
    configured_ids = load_configured_calendar_ids()
    if configured_ids:
        calendars = []
        for calendar_id in configured_ids:
            calendar = {"id": calendar_id, "summary": calendar_id}
            try:
                fetched = service.calendarList().get(calendarId=calendar_id).execute()
                if isinstance(fetched, dict):
                    calendar.update(fetched)
            except Exception:
                pass
            calendars.append(calendar)
        return calendars

    calendars = []
    page_token = None
    while True:
        response = service.calendarList().list(pageToken=page_token, showHidden=False).execute()
        calendars.extend(response.get("items", []))
        page_token = response.get("nextPageToken")
        if not page_token:
            break

    return calendars


def escape_xml(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
        .replace("'", "&apos;")
    )


def render_svg(events: list[EventBlock], width: int, height: int, output_path: Path) -> None:
    total_seconds = 24 * 60 * 60
    if events:
        render_tz = events[0].start.tzinfo or local_timezone()
    else:
        render_tz = local_timezone()
    window_start, _ = day_bounds(render_tz)
    bg_radius = height / 2
    now_seconds = max(0.0, min(float(total_seconds), (datetime.now(render_tz) - window_start).total_seconds()))
    now_x = now_seconds / total_seconds * width
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        f'<rect x="0" y="0" width="{width}" height="{height}" rx="{bg_radius}" ry="{bg_radius}" fill="#050505" />',
        f'<rect x="0.5" y="0.5" width="{width - 1}" height="{height - 1}" rx="{bg_radius - 0.5}" ry="{bg_radius - 0.5}" fill="none" stroke="#2f343b" stroke-width="1" />',
    ]

    for hour in range(1, 24):
        x = hour / 24 * width
        parts.append(f'<line x1="{x:.3f}" y1="3" x2="{x:.3f}" y2="{height - 3}" stroke="#1c2128" stroke-width="1" />')

    for event in events:
        start_seconds = max(0.0, (event.start - window_start).total_seconds())
        end_seconds = min(float(total_seconds), (event.end - window_start).total_seconds())
        x = start_seconds / total_seconds * width
        rect_width = max(1.0, (end_seconds - start_seconds) / total_seconds * width)
        fill = brighten_for_dark_bg(event.color)
        stroke = mix_colors(fill, "#ffffff", 0.18)
        parts.append(
            f'<rect x="{x:.3f}" y="1.5" width="{rect_width:.3f}" height="{height - 3}" rx="5" ry="5" fill="{escape_xml(fill)}" stroke="{escape_xml(stroke)}" stroke-width="1" />'
        )

    parts.append(f'<line x1="{now_x:.3f}" y1="0" x2="{now_x:.3f}" y2="{height}" stroke="#fff3bf" stroke-width="2" />')
    parts.append(f'<circle cx="{now_x:.3f}" cy="{height / 2:.3f}" r="3.2" fill="#fff3bf" />')

    parts.append("</svg>")
    output_path.write_text("".join(parts), encoding="utf-8")


def prune_old_svgs(cache_dir: Path) -> None:
    files = sorted(cache_dir.glob("timeline-*.svg"), key=lambda path: path.stat().st_mtime, reverse=True)
    for old_file in files[6:]:
        old_file.unlink(missing_ok=True)


def fetch_events(key_path: Path) -> list[EventBlock]:
    tz = local_timezone()
    window_start, window_end = day_bounds(tz)
    scopes = ["https://www.googleapis.com/auth/calendar.readonly"]
    credentials = service_account.Credentials.from_service_account_file(str(key_path), scopes=scopes)
    service = build("calendar", "v3", credentials=credentials, cache_discovery=False)

    colors = service.colors().get().execute()
    event_colors = colors.get("event", {})
    recurring_color_cache: dict[tuple[str, str], str | None] = {}

    calendars = discover_calendars(service)

    if not calendars:
        raise RuntimeError(
            "No calendars were discovered for the service account. "
            "Share calendars with the service account and/or provide calendar IDs in "
            f"{DEFAULT_CALENDAR_IDS_PATH}"
        )

    events: list[EventBlock] = []
    for calendar in calendars:
        calendar_id = calendar.get("id")
        if not calendar_id:
            continue

        calendar_name = calendar.get("summaryOverride") or calendar.get("summary") or calendar_id
        default_color = sanitize_color(calendar.get("backgroundColor"))
        page_token = None

        while True:
            response = service.events().list(
                calendarId=calendar_id,
                timeMin=rfc3339(window_start),
                timeMax=rfc3339(window_end),
                singleEvents=True,
                orderBy="startTime",
                pageToken=page_token,
            ).execute()

            for item in response.get("items", []):
                if item.get("status") == "cancelled" or item.get("transparency") == "transparent":
                    continue

                raw_start = item.get("start")
                raw_end = item.get("end")
                if not raw_start or not raw_end:
                    continue

                start, all_day = parse_event_time(raw_start, tz)
                end, _ = parse_event_time(raw_end, tz)
                clipped = clip_event(start, end, window_start, window_end)
                if not clipped:
                    continue

                color_id = item.get("colorId")
                if not color_id and item.get("recurringEventId"):
                    cache_key = (calendar_id, item["recurringEventId"])
                    if cache_key not in recurring_color_cache:
                        parent_color_id = None
                        try:
                            parent = service.events().get(calendarId=calendar_id, eventId=item["recurringEventId"]).execute()
                            parent_color_id = parent.get("colorId")
                        except Exception:
                            parent_color_id = None
                        recurring_color_cache[cache_key] = parent_color_id
                    color_id = recurring_color_cache[cache_key]

                event_color = default_color
                if color_id:
                    event_color = sanitize_color(event_colors.get(color_id, {}).get("background"))
                title = item.get("summary") or "Untitled"
                clipped_start, clipped_end = clipped

                events.append(
                    EventBlock(
                        calendar_name=calendar_name,
                        title=title,
                        start=clipped_start,
                        end=clipped_end,
                        color=event_color,
                        all_day=all_day,
                        has_custom_color=bool(color_id),
                    )
                )

            page_token = response.get("nextPageToken")
            if not page_token:
                break

    events.sort(key=lambda event: (event.start, event.end, event.calendar_name, event.title))
    return events


def output_payload(image_path: Path, tooltip: str, status: str) -> None:
    payload = {
        "image": str(image_path),
        "tooltip": tooltip,
        "status": status,
    }
    json.dump(payload, sys.stdout)
    sys.stdout.write("\n")


def main() -> int:
    key_path = Path(os.environ.get("GOOGLE_CALENDAR_SERVICE_ACCOUNT_JSON", DEFAULT_KEY_PATH))
    cache_dir = Path(os.environ.get("CALENDAR_TIMELINE_CACHE_DIR", DEFAULT_CACHE_DIR))
    width = int(os.environ.get("CALENDAR_TIMELINE_WIDTH", str(DEFAULT_WIDTH)))
    height = int(os.environ.get("CALENDAR_TIMELINE_HEIGHT", str(DEFAULT_HEIGHT)))
    cache_dir.mkdir(parents=True, exist_ok=True)
    image_path = cache_dir / f"timeline-{datetime.now().strftime('%Y%m%d-%H%M%S')}.svg"

    if not key_path.exists():
        render_svg([], width, height, image_path)
        output_payload(image_path, f"Missing Google service account key at {key_path}", "missing-key")
        return 0

    try:
        events = fetch_events(key_path)
        render_svg(events, width, height, image_path)
        prune_old_svgs(cache_dir)
        output_payload(image_path, build_tooltip(events), "ok")
        return 0
    except Exception as exc:
        render_svg([], width, height, image_path)
        prune_old_svgs(cache_dir)
        output_payload(image_path, f"Calendar timeline error: {exc}", "error")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
