"""Tests for demo_enrich — verifies fixture data and pipeline output."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

import demo_enrich
from enrich_alerts import Alert, EnrichedAlert, enrich_alert

FIXTURES = Path(__file__).parent.parent / "fixtures" / "sample_alerts.json"

_EXPECTED_RULE_IDS = {"100011", "5763", "2501", "5402", "100003"}


def test_fixtures_load_correct_count() -> None:
    raw: list[object] = json.loads(FIXTURES.read_text())
    assert len(raw) == 5


def test_demo_main_exits_zero() -> None:
    assert demo_enrich.main() == 0


def test_demo_output_contains_all_scenarios(capsys: pytest.CaptureFixture[str]) -> None:
    demo_enrich.main()
    out = capsys.readouterr().out

    for rule_id in ("100011", "5763", "2501", "5402", "100003"):
        assert rule_id in out, f"rule_id {rule_id} missing from output"

    for label in ("high", "medium", "low"):
        assert label in out, f"risk label '{label}' missing from output"


def test_load_sample_alerts_count() -> None:
    alerts = demo_enrich.load_sample_alerts()
    assert len(alerts) == 5


def test_load_sample_alerts_types() -> None:
    alerts = demo_enrich.load_sample_alerts()
    for alert in alerts:
        assert isinstance(alert, Alert)
        assert isinstance(alert.rule_id, str)
        assert isinstance(alert.level, int)
        assert isinstance(alert.description, str)
        assert alert.source_ip is None or isinstance(alert.source_ip, str)
        assert alert.mitre_id is None or isinstance(alert.mitre_id, str)
        assert isinstance(alert.timestamp, str)


def test_fixture_rule_ids() -> None:
    alerts = demo_enrich.load_sample_alerts()
    rule_ids = {a.rule_id for a in alerts}
    assert rule_ids == _EXPECTED_RULE_IDS


def test_round_trip_enrichment() -> None:
    alerts = demo_enrich.load_sample_alerts()
    for alert in alerts:
        enriched = enrich_alert(alert)
        assert isinstance(enriched, EnrichedAlert)
        assert enriched.risk_label, f"empty risk_label for rule {alert.rule_id}"


def test_main_output(capsys: pytest.CaptureFixture[str]) -> None:
    result = demo_enrich.main()
    assert result == 0
    out = capsys.readouterr().out
    assert "SOC Triage Report" in out
    for rule_id in _EXPECTED_RULE_IDS:
        assert rule_id in out, f"rule_id {rule_id} missing from main() output"
