# Offline-only by design — see ADR-0002. No new architecture.
"""End-to-end pipeline demo: Sigma → Wazuh XML → Alert enrichment → IR report."""

from __future__ import annotations

import json
from pathlib import Path

from enrich_alerts import Alert, enrich_alert
from report import generate_report
from sigma_convert import convert_to_wazuh_xml, parse_sigma_rule, validate_wazuh_rule

_TOOLS_DIR = Path(__file__).parent
_SIGMA_RULE = _TOOLS_DIR / "sigma" / "01-nmap-recon.yml"
_FIXTURE_JSON = _TOOLS_DIR / "fixtures" / "sample_enriched.json"


def _stage1() -> str:
    """Sigma → Wazuh XML: parse, convert, validate."""
    rule = parse_sigma_rule(_SIGMA_RULE)
    xml_str = convert_to_wazuh_xml(rule, base_id=100011)
    if not validate_wazuh_rule(xml_str):
        raise ValueError("Generated Wazuh XML failed validation")
    print(f"  Rule title : {rule.title}")
    print(f"  MITRE ID   : {rule.mitre_id}")
    print("  XML (first 3 lines):")
    for line in xml_str.splitlines()[:3]:
        print(f"    {line}")
    return xml_str


def _stage2() -> None:
    """Alert enrichment: load fixture first record, construct Alert, enrich."""
    records: list[dict[str, object]] = json.loads(_FIXTURE_JSON.read_text())
    first = records[0]
    src_ip = first.get("source_ip")
    mitre_val = first.get("mitre_id")
    alert = Alert(
        rule_id=str(first["rule_id"]),
        level=int(str(first["level"])),
        description=str(first["description"]),
        source_ip=str(src_ip) if src_ip is not None else None,
        mitre_id=str(mitre_val) if mitre_val is not None else None,
        timestamp=str(first["timestamp"]),
    )
    enriched = enrich_alert(alert)
    print(f"  Risk label       : {enriched.risk_label}")
    print(f"  MITRE description: {enriched.mitre_description}")


def _stage3() -> str:
    """Report generation: load all fixture records, generate Markdown."""
    records: list[dict[str, object]] = json.loads(_FIXTURE_JSON.read_text())
    md = generate_report(records)
    print("  First 15 lines:")
    for line in md.splitlines()[:15]:
        print(f"    {line}")
    return md


def main() -> int:
    """Run all three pipeline stages and print a summary."""
    print("=== Stage 1: Sigma → Wazuh XML ===")
    _stage1()

    print("\n=== Stage 2: Alert enrichment ===")
    _stage2()

    print("\n=== Stage 3: Report generation ===")
    _stage3()

    print(
        "\nPipeline demo complete.\n"
        "Stage 1: Sigma → Wazuh XML  [PASS]\n"
        "Stage 2: Alert enrichment    [PASS]\n"
        "Stage 3: Report generation   [PASS]"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
