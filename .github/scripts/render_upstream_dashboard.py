#!/usr/bin/env python3
"""Render nvchecker JSON as a deterministic, injection-safe issue body."""

from __future__ import annotations

import argparse
import html
import json
from pathlib import Path
import tomllib
from typing import Any
from urllib.parse import urlparse


MARKER = "<!-- edorp-upstream-dashboard -->"
POLICY_NAMES = {
    "live": "Live build",
    "manual": "Manual",
    "review": "Review",
    "snapshot": "Snapshot review",
}


def safe_text(value: object) -> str:
    """Escape untrusted values for an HTML element inside Markdown."""

    collapsed = " ".join(str(value).split())
    return (
        html.escape(collapsed, quote=True)
        .replace("@", "&#64;")
        .replace("|", "&#124;")
    )


def source_url(entry: dict[str, Any]) -> str | None:
    if repository := entry.get("github"):
        candidate = f"https://github.com/{repository}"
    elif project := entry.get("pypi"):
        candidate = f"https://pypi.org/project/{project}/"
    elif entry.get("source") == "regex":
        candidate = str(entry.get("url", ""))
    else:
        return None

    parsed = urlparse(candidate)
    if parsed.scheme != "https" or not parsed.netloc:
        raise ValueError(f"unsafe upstream URL: {candidate!r}")
    return candidate


def package_cell(atom: str, entry: dict[str, Any]) -> str:
    label = f"<code>{safe_text(atom)}</code>"
    if url := source_url(entry):
        return f'<a href="{html.escape(url, quote=True)}">{label}</a>'
    return label


def render_dashboard(
    updates: list[dict[str, Any]], config: dict[str, Any]
) -> str:
    pending = sorted(
        (
            update
            for update in updates
            if update.get("delta") in {"added", "new"}
        ),
        key=lambda update: str(update.get("name", "")),
    )
    if not pending:
        return ""

    lines = [
        MARKER,
        "## Pending upstream updates",
        "",
        "This issue is maintained automatically. A detected version is a review "
        "signal, not approval to merge a bump.",
        "",
        "| Package | Current | Upstream | Handling | Atomic group |",
        "| --- | --- | --- | --- | --- |",
    ]
    notes: list[tuple[str, str]] = []

    for update in pending:
        atom = str(update.get("name", ""))
        if not atom or atom not in config:
            raise ValueError(f"update has no matching config entry: {atom!r}")
        entry = config[atom]
        policy = str(entry.get("policy", "review"))
        if policy not in POLICY_NAMES:
            raise ValueError(f"unknown policy {policy!r} for {atom}")

        current = update.get("oldver")
        current_cell = "&mdash;" if current is None else safe_text(current)
        group = entry.get("group")
        group_cell = "&mdash;" if not group else safe_text(group)
        lines.append(
            "| "
            f"{package_cell(atom, entry)} | "
            f"<code>{current_cell}</code> | "
            f"<code>{safe_text(update.get('newver', ''))}</code> | "
            f"{safe_text(POLICY_NAMES[policy])} | "
            f"{group_cell} |"
        )
        if note := entry.get("note"):
            notes.append((atom, str(note)))

    if notes:
        lines.extend(["", "### Review constraints", ""])
        for atom, note in notes:
            lines.append(
                f"- <code>{safe_text(atom)}</code>: {safe_text(note)}"
            )

    lines.extend(
        [
            "",
            "After a bump passes build tests and QA, update "
            "<code>.github/upstream-old.json</code> in the same pull request.",
            "",
        ]
    )
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--updates", type=Path, required=True)
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    updates = json.loads(args.updates.read_text(encoding="utf-8"))
    with args.config.open("rb") as file:
        config = tomllib.load(file)
    body = render_dashboard(updates, config)
    args.output.write_text(body, encoding="utf-8")


if __name__ == "__main__":
    main()
