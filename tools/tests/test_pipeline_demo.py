"""Tests for the end-to-end pipeline demo (TASK-019)."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from pipeline_demo import main
from report import generate_report
from sigma_convert import convert_to_wazuh_xml, parse_sigma_rule, validate_wazuh_rule

_TOOLS_DIR = Path(__file__).parent.parent
_SIGMA_RULE = _TOOLS_DIR / "sigma" / "01-nmap-recon.yml"
_FIXTURE_JSON = _TOOLS_DIR / "fixtures" / "sample_enriched.json"


def test_pipeline_demo_runs(capsys: pytest.CaptureFixture[str]) -> None:
    """main() returns exit code 0 and prints exactly 3 [PASS] markers."""
    assert main() == 0
    out = capsys.readouterr().out
    assert out.count("[PASS]") == 3


def test_pipeline_demo_stage1_produces_xml() -> None:
    """Stage 1 logic produces valid XML containing <rule>."""
    rule = parse_sigma_rule(_SIGMA_RULE)
    xml_str = convert_to_wazuh_xml(rule, base_id=100011)
    assert validate_wazuh_rule(xml_str)
    assert "<rule" in xml_str
    assert rule.mitre_id is not None


def test_pipeline_demo_stage3_contains_summary() -> None:
    """Stage 3 logic produces Markdown containing the ## Summary section."""
    records: list[dict[str, object]] = json.loads(_FIXTURE_JSON.read_text())
    md = generate_report(records)
    assert "## Summary" in md
