"""End-to-end offline pipeline integration tests.

Covers the full Phase 2 pipeline without live network calls:
  1. Sigma YAML  → parse_sigma_rule()    → SigmaRule
  2. SigmaRule   → convert_to_wazuh_xml() → XML string
  3. XML string  → validate_wazuh_rule()  → True
  4. Alert       → enrich_alert()         → EnrichedAlert
  5. records[]   → generate_report()      → Markdown string
"""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from enrich_alerts import Alert, EnrichedAlert, enrich_alert
from report import generate_report
from sigma_convert import SigmaRule, convert_to_wazuh_xml, parse_sigma_rule, validate_wazuh_rule

_SIGMA_DIR = Path(__file__).parent.parent / "sigma"
_FIXTURE_JSON = Path(__file__).parent.parent / "fixtures" / "sample_enriched.json"

_SIGMA_FILES: list[Path] = sorted(_SIGMA_DIR.glob("*.yml"))

_SECTION_HEADERS = [
    "## Summary",
    "## Alert Table",
    "## MITRE Techniques",
    "## Recommended Triage Actions",
]


# ── Steps 1-3: Sigma YAML → Wazuh XML ────────────────────────────────────────


@pytest.mark.parametrize("sigma_path", _SIGMA_FILES, ids=[p.name for p in _SIGMA_FILES])
def test_sigma_rule_parses(sigma_path: Path) -> None:
    """Step 1: each Sigma YAML parses to a SigmaRule with a non-empty title."""
    rule = parse_sigma_rule(sigma_path)
    assert isinstance(rule, SigmaRule)
    assert rule.title


@pytest.mark.parametrize("sigma_path", _SIGMA_FILES, ids=[p.name for p in _SIGMA_FILES])
def test_sigma_produces_valid_wazuh_xml(sigma_path: Path) -> None:
    """Steps 2-3: each Sigma rule converts to valid, parseable Wazuh XML."""
    rule = parse_sigma_rule(sigma_path)
    xml_str = convert_to_wazuh_xml(rule, base_id=100500)
    assert validate_wazuh_rule(xml_str), f"Invalid XML for {sigma_path.name}:\n{xml_str}"


# ── Step 4: Alert enrichment ──────────────────────────────────────────────────


def test_enrich_alert_risk_label() -> None:
    """Step 4: enrich_alert maps level >= 12 to 'critical'."""
    alert = Alert(
        rule_id="5763",
        level=12,
        description="Successful authentication after multiple failures",
        source_ip="192.0.2.10",
        mitre_id="T1110.001",
        timestamp="2026-02-14T00:05:00Z",
    )
    enriched = enrich_alert(alert)
    assert isinstance(enriched, EnrichedAlert)
    assert enriched.risk_label == "critical"


def test_enrich_alert_mitre_description() -> None:
    """Step 4: enrich_alert resolves a known MITRE ID to its description."""
    alert = Alert(
        rule_id="100011",
        level=6,
        description="Network port scan detected",
        source_ip="192.0.2.10",
        mitre_id="T1046",
        timestamp="2026-02-14T00:00:00Z",
    )
    enriched = enrich_alert(alert)
    assert enriched.mitre_description == "Network Service Discovery"


# ── Step 5: Report generation ─────────────────────────────────────────────────


def test_report_from_fixture_is_nonempty() -> None:
    """Step 5: generate_report on the fixture JSON returns a non-empty string."""
    records: list[dict[str, object]] = json.loads(_FIXTURE_JSON.read_text())
    md = generate_report(records)
    assert md.strip()


def test_report_from_fixture_contains_section_headers() -> None:
    """Step 5: report output contains all 4 required Markdown section headers."""
    records: list[dict[str, object]] = json.loads(_FIXTURE_JSON.read_text())
    md = generate_report(records)
    for header in _SECTION_HEADERS:
        assert header in md, f"Missing section header: {header!r}"
