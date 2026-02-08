"""Replay sample alerts through the enrichment pipeline — no VMs or env vars needed."""

from __future__ import annotations

import json
from dataclasses import asdict
from pathlib import Path

from enrich_alerts import Alert, enrich_alert, format_triage_report

FIXTURES = Path(__file__).parent / "fixtures" / "sample_alerts.json"


def load_sample_alerts() -> list[Alert]:
    """Load Alert objects from the bundled fixture file."""
    raw: list[dict[str, object]] = json.loads(FIXTURES.read_text())
    return [
        Alert(
            rule_id=str(item["rule_id"]),
            level=int(str(item["level"])),
            description=str(item["description"]),
            source_ip=str(item["source_ip"]) if item.get("source_ip") else None,
            mitre_id=str(item["mitre_id"]) if item.get("mitre_id") else None,
            timestamp=str(item["timestamp"]),
        )
        for item in raw
    ]


def main() -> int:
    """Replay sample alerts and print triage report + JSON."""
    alerts = load_sample_alerts()
    enriched = [enrich_alert(a) for a in alerts]

    print(format_triage_report(enriched))
    print("\nJSON\n----")
    print(json.dumps([asdict(item) for item in enriched], indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
