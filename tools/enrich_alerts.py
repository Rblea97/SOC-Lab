"""Fetch and enrich Wazuh alerts for analyst triage."""

from __future__ import annotations

import json
import os
from dataclasses import asdict, dataclass
from datetime import UTC, datetime, timedelta
from typing import Any

import requests

MITRE_DESCRIPTIONS: dict[str, str] = {
    "T1046": "Network Service Discovery",
    "T1110.001": "Password Guessing",
    "T1190": "Exploit Public-Facing Application",
    "T1505.003": "Web Shell",
    "T1548": "Abuse Elevation Control Mechanism",
}


@dataclass(slots=True)
class Alert:
    rule_id: str
    level: int
    description: str
    source_ip: str | None
    mitre_id: str | None
    timestamp: str


@dataclass(slots=True)
class EnrichedAlert:
    alert: Alert
    risk_label: str
    mitre_description: str | None


def _risk_label(level: int) -> str:
    if level >= 12:
        return "critical"
    if level >= 8:
        return "high"
    if level >= 5:
        return "medium"
    return "low"


def fetch_alerts(
    api_url: str,
    username: str,
    password: str,
    min_level: int,
    minutes: int,
    verify: bool | str = True,
) -> list[Alert]:
    """Fetch recent alerts from Wazuh API."""
    cutoff = datetime.now(UTC) - timedelta(minutes=minutes)
    cutoff_iso = cutoff.strftime("%Y-%m-%dT%H:%M:%SZ")
    endpoint = f"{api_url.rstrip('/')}/alerts"
    params: dict[str, str | int] = {
        "q": f"rule.level>={min_level};timestamp>{cutoff_iso}",
        "sort": "-timestamp",
        "limit": 100,
    }

    response = requests.get(
        endpoint, params=params, auth=(username, password), timeout=15, verify=verify
    )
    response.raise_for_status()
    payload: dict[str, Any] = response.json()
    items: list[dict[str, Any]] = payload.get("data", {}).get("affected_items", [])

    alerts: list[Alert] = []
    for item in items:
        rule = item.get("rule", {})
        mitre_ids: list[str] = rule.get("mitre", {}).get("id", [])
        alerts.append(
            Alert(
                rule_id=str(rule.get("id", "unknown")),
                level=int(rule.get("level", 0)),
                description=str(rule.get("description", "")),
                source_ip=item.get("agent", {}).get("ip"),
                mitre_id=mitre_ids[0] if mitre_ids else None,
                timestamp=str(item.get("timestamp", "")),
            )
        )
    return alerts


def enrich_alert(alert: Alert) -> EnrichedAlert:
    """Attach risk and MITRE context to an alert."""
    mitre_description = MITRE_DESCRIPTIONS.get(alert.mitre_id or "")
    return EnrichedAlert(
        alert=alert,
        risk_label=_risk_label(alert.level),
        mitre_description=mitre_description,
    )


def format_triage_report(alerts: list[EnrichedAlert]) -> str:
    """Render a concise text report suitable for analyst notes."""
    if not alerts:
        return "No alerts matched the query."

    lines = ["SOC Triage Report", "================="]
    for idx, entry in enumerate(alerts, start=1):
        mitre = (
            f"{entry.alert.mitre_id} ({entry.mitre_description})" if entry.alert.mitre_id else "n/a"
        )
        header = (
            f"{idx}. Rule {entry.alert.rule_id} level={entry.alert.level} risk={entry.risk_label}"
        )
        lines.extend(
            [
                header,
                f"   Time: {entry.alert.timestamp}",
                f"   Source: {entry.alert.source_ip or 'unknown'}",
                f"   MITRE: {mitre}",
                f"   Desc: {entry.alert.description}",
            ]
        )
    return "\n".join(lines)


def main() -> int:
    """CLI entrypoint."""
    api_url = os.environ.get("WAZUH_API_URL", "https://192.168.10.14:55000")
    username = os.environ.get("WAZUH_API_USER")
    password = os.environ.get("WAZUH_API_PASSWORD")
    min_level = int(os.environ.get("WAZUH_MIN_LEVEL", "8"))
    minutes = int(os.environ.get("WAZUH_WINDOW_MINUTES", "30"))

    if not username or not password:
        print("Missing WAZUH_API_USER or WAZUH_API_PASSWORD.")
        return 1

    _tls_env = os.environ.get("WAZUH_TLS_VERIFY", "1")
    tls_verify: bool | str
    if _tls_env == "0":
        import warnings

        warnings.warn(
            "TLS verification disabled (WAZUH_TLS_VERIFY=0). "
            "Do not use this outside a lab environment.",
            stacklevel=1,
        )
        tls_verify = False
    else:
        tls_verify = os.environ.get("WAZUH_CA_BUNDLE", True)  # True = default CA bundle

    alerts = fetch_alerts(api_url, username, password, min_level, minutes, verify=tls_verify)
    enriched = [enrich_alert(alert) for alert in alerts]

    print(format_triage_report(enriched))
    print("\nJSON\n----")
    print(json.dumps([asdict(item) for item in enriched], indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
