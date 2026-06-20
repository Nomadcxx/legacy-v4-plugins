#!/usr/bin/env python3
"""Hermes lifecycle hook writer for the Noctalia Hermes plugin."""

from __future__ import annotations

import json
import os
import sys
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path


BUSY_EVENTS = {
    "pre_llm_call",
    "post_llm_call",
    "pre_tool_call",
    "post_tool_call",
    "on_session_start",
}
ATTENTION_EVENTS = {"pre_approval_request"}
IDLE_EVENTS = {"post_approval_response", "on_session_end", "on_session_finalize"}


def hermes_home() -> Path:
    return Path(os.environ.get("HERMES_HOME", "~/.hermes")).expanduser()


def event_status(event: str) -> str:
    if event in BUSY_EVENTS:
        return "busy"
    if event in ATTENTION_EVENTS:
        return "attention"
    if event in IDLE_EVENTS:
        return "idle"
    return "unknown"


def atomic_write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(f"{path.name}.{uuid.uuid4().hex}.tmp")
    tmp.write_text(json.dumps(data, ensure_ascii=False, sort_keys=True) + "\n")
    tmp.replace(path)


def write_signal(event: str, signal_path: Path | None = None) -> dict:
    target = signal_path or hermes_home() / "status_signal"
    data = {
        "event": event,
        "status": event_status(event),
        "ts": datetime.now(timezone.utc).isoformat(),
        "time": time.time(),
    }
    atomic_write_json(Path(target).expanduser(), data)
    return data


def main(argv: list[str] | None = None) -> int:
    args = argv if argv is not None else sys.argv[1:]
    if not args:
        print("usage: hermes_status_hook.py <event>", file=sys.stderr)
        return 2
    data = write_signal(args[0])
    print(json.dumps(data, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
