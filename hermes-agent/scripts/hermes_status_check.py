#!/usr/bin/env python3
"""Emit normalized Hermes status JSON for the Noctalia Hermes plugin."""

from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path
from typing import Any


BUSY_STALE_SECONDS = 30


def hermes_home() -> Path:
    return Path(os.environ.get("HERMES_HOME", "~/.hermes")).expanduser()


def read_json(path: Path, default: Any) -> Any:
    try:
        return json.loads(path.read_text())
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return default


def read_pid(path: Path) -> str:
    try:
        return path.read_text().strip()
    except OSError:
        return ""


def pid_alive(pid: str) -> bool:
    if not pid or not pid.isdigit():
        return False
    return Path("/proc") .joinpath(pid).exists()


def signal_status(home: Path) -> tuple[str, str, str, float]:
    data = read_json(home / "status_signal", {})
    if not isinstance(data, dict):
        return "", "", "", 0.0
    if not data:
        return "", "", "", 0.0
    event = str(data.get("event") or "")
    status = str(data.get("status") or "")
    ts = str(data.get("ts") or "")
    signal_time = float(data.get("time") or 0)
    age = max(0.0, time.time() - signal_time) if signal_time else 0.0
    return event, status, ts, age


def platform_status(home: Path) -> dict[str, Any]:
    data = read_json(home / "gateway_state.json", {})
    if not isinstance(data, dict):
        return {}
    platforms = data.get("platforms", data)
    return platforms if isinstance(platforms, dict) else {}


def has_degraded_platform(platforms: dict[str, Any]) -> bool:
    for value in platforms.values():
        if isinstance(value, dict) and value.get("state") not in (None, "connected", "online", "ok"):
            return True
    return False


def build_status(home: Path | None = None) -> dict[str, Any]:
    root = home or hermes_home()
    gateway_pid = read_pid(root / "gateway.pid")
    cli_pid = read_pid(root / "cli.pid")
    gateway_running = pid_alive(gateway_pid)
    cli_active = pid_alive(cli_pid)
    needs_attention = (root / "needs_attention").exists()
    signal_event, signal_state, signal_ts, signal_age = signal_status(root)
    platforms = platform_status(root)

    if needs_attention or signal_state == "attention":
        status = "attention"
    elif not gateway_running:
        status = "offline"
    elif has_degraded_platform(platforms):
        status = "degraded"
    elif signal_state == "busy" and signal_age <= BUSY_STALE_SECONDS:
        status = "busy"
    else:
        status = "idle"

    return {
        "status": status,
        "gateway_running": gateway_running,
        "gateway_pid": gateway_pid if gateway_running else "",
        "cli_active": cli_active,
        "cli_pid": cli_pid if cli_active else "",
        "needs_attention": needs_attention,
        "signal_event": signal_event,
        "signal_ts": signal_ts,
        "signal_age": int(signal_age) if signal_age else 0,
        "platforms": platforms,
        "usage": {},
    }


def main() -> int:
    print(json.dumps(build_status(), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
