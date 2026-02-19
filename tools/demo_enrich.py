"""Replay enriched alerts offline — no env vars or network calls needed."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from enrich_alerts import Alert, EnrichedAlert, format_triage_report

_ALERTS_FIXTURE = Path(__file__).parent / "fixtures" / "sample_alerts.json"
_ENRICHED_FIXTURE = Path(__file__).parent / "fixtures" / "sample_enriched.json"


def load_sample_alerts() -> list[Alert]:
    """Load Alert objects from the bundled raw alert fixture."""
    raw: list[dict[str, Any]] = json.loads(_ALERTS_FIXTURE.read_text())
    return [
        Alert(
            rule_id=str(item["rule_id"]),
            level=int(str(item["level"])),
            description=str(item["description"]),
            source_ip=str(item["source_ip"]) if item.get("source_ip") is not None else None,
            mitre_id=str(item["mitre_id"]) if item.get("mitre_id") is not None else None,
            timestamp=str(item["timestamp"]),
        )
        for item in raw
    ]


def _to_enriched(item: dict[str, Any]) -> EnrichedAlert:
    """Reconstruct an EnrichedAlert from a flat fixture record."""
    alert = Alert(
        rule_id=str(item["rule_id"]),
        level=int(str(item["level"])),
        description=str(item["description"]),
        source_ip=str(item["source_ip"]) if item.get("source_ip") is not None else None,
        mitre_id=str(item["mitre_id"]) if item.get("mitre_id") is not None else None,
        timestamp=str(item["timestamp"]),
    )
    return EnrichedAlert(
        alert=alert,
        risk_label=str(item["risk_label"]),
        mitre_description=str(item["mitre_description"])
        if item.get("mitre_description") is not None
        else None,
    )


def main() -> int:
    """Replay enriched alerts offline and print triage report + JSON."""
    raw: list[dict[str, Any]] = json.loads(_ENRICHED_FIXTURE.read_text())
    enriched = [_to_enriched(item) for item in raw]

    print(format_triage_report(enriched))
    print("\nJSON\n----")
    print(json.dumps(raw, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
