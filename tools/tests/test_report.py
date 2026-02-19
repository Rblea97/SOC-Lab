"""Tests for tools/report.py."""

from __future__ import annotations

import json
from pathlib import Path

from report import generate_report, main

_FIXTURE = Path(__file__).parent.parent / "fixtures" / "sample_enriched.json"

_SECTION_HEADERS = [
    "## Summary",
    "## Alert Table",
    "## MITRE Techniques",
    "## Recommended Triage Actions",
]


def test_report_writes_file(tmp_path: Path) -> None:
    """main() writes <input-stem>.md to the same directory as the input."""
    input_path = tmp_path / "sample_enriched.json"
    input_path.write_text(_FIXTURE.read_text())
    assert main([str(input_path)]) == 0
    assert (tmp_path / "sample_enriched.md").exists()


def test_report_contains_all_section_headers(tmp_path: Path) -> None:
    """Output Markdown contains all 4 required section headers."""
    input_path = tmp_path / "sample_enriched.json"
    input_path.write_text(_FIXTURE.read_text())
    main([str(input_path)])
    content = (tmp_path / "sample_enriched.md").read_text()
    for header in _SECTION_HEADERS:
        assert header in content, f"Missing section header: {header!r}"


def test_report_alert_count_matches_fixture(tmp_path: Path) -> None:
    """Alert count in the report matches the number of records in the fixture."""
    input_path = tmp_path / "sample_enriched.json"
    input_path.write_text(_FIXTURE.read_text())
    records: list[dict[str, object]] = json.loads(_FIXTURE.read_text())
    main([str(input_path)])
    content = (tmp_path / "sample_enriched.md").read_text()
    assert f"**Alert count:** {len(records)}" in content


def test_report_no_args_returns_1() -> None:
    """main() with no arguments returns exit code 1."""
    assert main([]) == 1


def test_report_missing_file_returns_1() -> None:
    """main() returns 1 if the input file does not exist."""
    assert main(["/tmp/nonexistent_report_abc123.json"]) == 1


def test_generate_report_empty_list() -> None:
    """generate_report handles an empty record list gracefully."""
    content = generate_report([])
    assert "## Summary" in content
    assert "**Alert count:** 0" in content
