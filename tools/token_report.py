#!/usr/bin/env python3
"""Summarise Claude Code token usage for the session(s) that built this project.

Reads the Claude Code JSONL transcripts (main session + subagents), de-duplicates
assistant messages by message id, and writes a Markdown report.

Usage:
    python3 tools/token_report.py --project-dir ~/.claude/projects/<slug> \
        [--session <uuid>] [--out docs/TOKENS.md]
"""

from __future__ import annotations

import argparse
import json
from collections import defaultdict
from datetime import datetime
from pathlib import Path

FIELDS = (
    "input_tokens",
    "output_tokens",
    "cache_creation_input_tokens",
    "cache_read_input_tokens",
)


def iter_transcripts(project_dir: Path, session: str | None) -> list[Path]:
    files = sorted(project_dir.glob("*.jsonl"))
    if session:
        files = [f for f in files if f.stem == session]
        sub = project_dir / session / "subagents"
        files += sorted(sub.glob("*.jsonl")) if sub.exists() else []
    else:
        files += sorted(project_dir.glob("*/subagents/*.jsonl"))
    return files


def collect(files: list[Path]) -> tuple[dict[str, dict[str, int]], int, list[str]]:
    seen: set[str] = set()
    by_model: dict[str, dict[str, int]] = defaultdict(lambda: dict.fromkeys(FIELDS, 0))
    turns = 0
    stamps: list[str] = []
    for path in files:
        for line in path.read_text(encoding="utf-8").splitlines():
            try:
                rec = json.loads(line)
            except json.JSONDecodeError:
                continue
            msg = rec.get("message") or {}
            usage = msg.get("usage")
            if rec.get("type") != "assistant" or not usage:
                continue
            key = f"{msg.get('id')}:{rec.get('requestId')}"
            if key in seen:
                continue
            seen.add(key)
            turns += 1
            if ts := rec.get("timestamp"):
                stamps.append(ts)
            bucket = by_model[msg.get("model", "unknown")]
            for f in FIELDS:
                bucket[f] += int(usage.get(f) or 0)
    return by_model, turns, sorted(stamps)


def render(by_model: dict[str, dict[str, int]], turns: int, stamps: list[str], n_files: int) -> str:
    total = dict.fromkeys(FIELDS, 0)
    rows = []
    for model, u in sorted(by_model.items()):
        for f in FIELDS:
            total[f] += u[f]
        rows.append(f"| {model} | " + " | ".join(f"{u[f]:,}" for f in FIELDS) + f" | {sum(u.values()):,} |")
    grand = sum(total.values())
    span = f"{stamps[0]} → {stamps[-1]}" if stamps else "n/a"
    return "\n".join(
        [
            "# Token Usage — Building Brainstash with Claude Code",
            "",
            f"_Generated {datetime.now().isoformat(timespec='minutes')} by `tools/token_report.py`._",
            "",
            f"- Transcripts read: **{n_files}** (main session + subagents)",
            f"- Assistant API turns: **{turns:,}**",
            f"- Time span: {span}",
            f"- **Grand total tokens: {grand:,}**",
            f"  - Fresh input: {total['input_tokens']:,}",
            f"  - Output: {total['output_tokens']:,}",
            f"  - Cache writes: {total['cache_creation_input_tokens']:,}",
            f"  - Cache reads: {total['cache_read_input_tokens']:,}",
            "",
            "| Model | Input | Output | Cache write | Cache read | Total |",
            "|---|---|---|---|---|---|",
            *rows,
            "",
            "Cache reads dominate because each turn re-reads the cached conversation; they are",
            "billed at a fraction of fresh input. Output tokens are what Claude actually wrote.",
            "",
        ]
    )


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--project-dir", type=Path, required=True)
    ap.add_argument("--session")
    ap.add_argument("--out", type=Path, default=Path("docs/TOKENS.md"))
    args = ap.parse_args()
    files = iter_transcripts(args.project_dir.expanduser(), args.session)
    by_model, turns, stamps = collect(files)
    report = render(by_model, turns, stamps, len(files))
    args.out.write_text(report, encoding="utf-8")
    print(report)


if __name__ == "__main__":
    main()
