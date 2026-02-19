"""report.py — Generate a Markdown IR summary from an enriched alert JSON file."""

from __future__ import annotations

import json
import sys
from pathlib import Path

TRIAGE_ACTIONS: dict[str, str] = {
    "critical": "Escalate to T2 immediately; isolate affected host",
    "high": "Escalate to T2; isolate host if confirmed",
    "medium": "Investigate during shift; document findings",
    "low": "Log and monitor; no immediate action required",
}

_RISK_ORDER = ("critical", "high", "medium", "low")


def _date_range(records: list[dict[str, object]]) -> tuple[str, str]:
    timestamps = sorted(str(r["timestamp"]) for r in records)
    return timestamps[0], timestamps[-1]


def _risk_breakdown(records: list[dict[str, object]]) -> dict[str, int]:
    breakdown: dict[str, int] = {}
    for r in records:
        label = str(r["risk_label"])
        breakdown[label] = breakdown.get(label, 0) + 1
    return breakdown


def generate_report(records: list[dict[str, object]]) -> str:
    """Return a Markdown IR summary string for the given enriched alert records."""
    parts: list[str] = []

    # 1. Summary
    parts.append("# IR Summary Report")
    parts.append("")
    parts.append("## Summary")
    parts.append("")
    count = len(records)
    parts.append(f"- **Alert count:** {count}")
    if records:
        start, end = _date_range(records)
        parts.append(f"- **Date range:** {start} — {end}")
    else:
        parts.append("- **Date range:** N/A")
    breakdown = _risk_breakdown(records)
    parts.append("- **Risk label breakdown:**")
    for label in _RISK_ORDER:
        parts.append(f"  - {label}: {breakdown.get(label, 0)}")
    parts.append("")

    # 2. Alert Table
    parts.append("## Alert Table")
    parts.append("")
    parts.append("| Rule ID | Risk | MITRE | Timestamp | Source IP |")
    parts.append("|---|---|---|---|---|")
    for r in records:
        rule_id = str(r.get("rule_id", ""))
        risk = str(r.get("risk_label", ""))
        mitre_raw = r.get("mitre_id")
        mitre = str(mitre_raw) if mitre_raw is not None else "n/a"
        ts = str(r.get("timestamp", ""))
        src_raw = r.get("source_ip")
        src = str(src_raw) if src_raw is not None else "n/a"
        parts.append(f"| {rule_id} | {risk} | {mitre} | {ts} | {src} |")
    parts.append("")

    # 3. MITRE Techniques
    parts.append("## MITRE Techniques")
    parts.append("")
    seen: dict[str, str] = {}
    for r in records:
        mid = r.get("mitre_id")
        mdesc = r.get("mitre_description")
        if isinstance(mid, str) and mid not in seen:
            seen[mid] = str(mdesc) if isinstance(mdesc, str) else ""
    if seen:
        for mid, desc in seen.items():
            entry = f"- **{mid}**"
            if desc:
                entry += f" — {desc}"
            parts.append(entry)
    else:
        parts.append("- No MITRE techniques recorded.")
    parts.append("")

    # 4. Recommended Triage Actions
    parts.append("## Recommended Triage Actions")
    parts.append("")
    for label in _RISK_ORDER:
        parts.append(f"- **{label}:** {TRIAGE_ACTIONS[label]}")
    parts.append("")

    return "\n".join(parts)


def main(argv: list[str] | None = None) -> int:
    """Entry point: parse CLI args, read JSON, write Markdown."""
    args: list[str] = argv if argv is not None else sys.argv[1:]
    if len(args) != 1:
        print("Usage: report.py <enriched.json>", file=sys.stderr)
        return 1
    input_path = Path(args[0])
    if not input_path.exists():
        print(f"File not found: {input_path}", file=sys.stderr)
        return 1
    records: list[dict[str, object]] = json.loads(input_path.read_text())
    output_path = input_path.with_suffix(".md")
    output_path.write_text(generate_report(records))
    print(f"Report written to {output_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
