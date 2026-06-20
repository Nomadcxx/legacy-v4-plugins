#!/usr/bin/env python3
"""Manual attention flag helper for the Noctalia Hermes plugin."""

from __future__ import annotations

import os
import sys
from pathlib import Path


def hermes_home() -> Path:
    return Path(os.environ.get("HERMES_HOME", "~/.hermes")).expanduser()


def attention_file(home: Path | None = None) -> Path:
    return (home or hermes_home()) / "needs_attention"


def set_attention(home: Path | None = None) -> None:
    path = attention_file(home)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("manual\n")


def clear_attention(home: Path | None = None) -> None:
    try:
        attention_file(home).unlink()
    except FileNotFoundError:
        pass


def attention_status(home: Path | None = None) -> str:
    return "set" if attention_file(home).exists() else "clear"


def main(argv: list[str] | None = None) -> int:
    args = argv if argv is not None else sys.argv[1:]
    action = args[0] if args else "status"
    if action == "set":
        set_attention()
    elif action == "clear":
        clear_attention()
    elif action != "status":
        print("usage: hermes_attention.py [set|clear|status]", file=sys.stderr)
        return 2
    print(attention_status())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
