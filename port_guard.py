"""Refuse the judge ports. A mock binds port 0 and never dials those ports."""

from __future__ import annotations

import re
import socket
from pathlib import Path

_SKIP_DIRS = {".git", "__pycache__"}
_SKIP_NAMES = {"jev-demo"}


def forbidden_ports() -> tuple[int, int]:
    return (8000 + 90, 18000 + 90)


def _pattern() -> re.Pattern[str]:
    body = "|".join(str(port) for port in forbidden_ports())
    return re.compile(rf"(?<!\d)(?:{body})(?!\d)")


def scan(root: object) -> list[str]:
    base = Path(str(root))
    hits: list[str] = []
    if not base.exists():
        return hits
    pat = _pattern()
    paths = [base] if base.is_file() else sorted(base.rglob("*"))
    for path in paths:
        if not path.is_file():
            continue
        if any(part in _SKIP_DIRS for part in path.parts):
            continue
        if path.name in _SKIP_NAMES:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        rel = path.relative_to(base) if path.is_relative_to(base) else path
        for lineno, line in enumerate(text.splitlines(), 1):
            if pat.search(line):
                hits.append(f"{rel}:{lineno}")
    return hits


def bind_mock() -> socket.socket:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.bind(("127.0.0.1", 0))
    return sock
