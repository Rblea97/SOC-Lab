from unittest.mock import MagicMock, patch

import pytest

from enrich_alerts import (
    Alert,
    _risk_label,
    enrich_alert,
    fetch_alerts,
    format_triage_report,
    main,
)

# ---------------------------------------------------------------------------
# _risk_label boundary tests
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    "level,expected",
    [
        (0, "low"),
        (4, "low"),
        (5, "medium"),
        (7, "medium"),
        (8, "high"),
        (11, "high"),
        (12, "critical"),
        (15, "critical"),
    ],
)
def test_risk_label_boundaries(level: int, expected: str) -> None:
    assert _risk_label(level) == expected


# ---------------------------------------------------------------------------
# enrich_alert + format_triage_report happy path
# ---------------------------------------------------------------------------


def test_enrich_and_report_happy_path() -> None:
    alert = Alert(
        rule_id="100002",
        level=12,
        description="Successful SSH login after multiple failures",
        source_ip="192.168.10.11",
        mitre_id="T1110.001",
        timestamp="2026-02-13T00:00:00Z",
    )
    enriched = enrich_alert(alert)

    assert enriched.risk_label == "critical"
    assert enriched.mitre_description == "Password Guessing"

    report = format_triage_report([enriched])
    assert "SOC Triage Report" in report
    assert "Rule 100002" in report
    assert "risk=critical" in report


def test_empty_alert_list() -> None:
    report = format_triage_report([])
    assert report == "No alerts matched the query."


def test_enrich_unknown_mitre_id() -> None:
    alert = Alert(
        rule_id="99999",
        level=6,
        description="Unknown technique",
        source_ip=None,
        mitre_id="T9999",
        timestamp="2026-02-13T00:00:00Z",
    )
    enriched = enrich_alert(alert)
    assert enriched.risk_label == "medium"
    assert enriched.mitre_description is None


def test_enrich_no_mitre_id() -> None:
    alert = Alert(
        rule_id="50000",
        level=3,
        description="Low severity event",
        source_ip="10.0.0.1",
        mitre_id=None,
        timestamp="2026-02-13T00:00:00Z",
    )
    enriched = enrich_alert(alert)
    assert enriched.risk_label == "low"
    assert enriched.mitre_description is None
    report = format_triage_report([enriched])
    assert "MITRE: n/a" in report


# ---------------------------------------------------------------------------
# fetch_alerts with mocked HTTP
# ---------------------------------------------------------------------------


def _make_alert_payload(rule_id: str = "100011", level: int = 10) -> dict:
    return {
        "data": {
            "affected_items": [
                {
                    "rule": {
                        "id": rule_id,
                        "level": level,
                        "description": "Mocked alert",
                        "mitre": {"id": ["T1046"]},
                    },
                    "agent": {"ip": "192.168.10.11"},
                    "timestamp": "2026-02-13T00:00:00Z",
                }
            ]
        }
    }


def test_fetch_alerts_returns_alerts() -> None:
    mock_response = MagicMock()
    mock_response.json.return_value = _make_alert_payload()
    mock_response.raise_for_status.return_value = None

    with patch("enrich_alerts.requests.get", return_value=mock_response) as mock_get:
        alerts = fetch_alerts(
            api_url="https://192.168.10.14:55000",
            username="admin",
            password="secret",
            min_level=5,
            minutes=30,
        )

    assert len(alerts) == 1
    assert alerts[0].rule_id == "100011"
    assert alerts[0].level == 10
    assert alerts[0].mitre_id == "T1046"
    mock_get.assert_called_once()


def test_fetch_alerts_empty_response() -> None:
    mock_response = MagicMock()
    mock_response.json.return_value = {"data": {"affected_items": []}}
    mock_response.raise_for_status.return_value = None

    with patch("enrich_alerts.requests.get", return_value=mock_response):
        alerts = fetch_alerts(
            api_url="https://192.168.10.14:55000",
            username="admin",
            password="secret",
            min_level=5,
            minutes=30,
        )

    assert alerts == []


# ---------------------------------------------------------------------------
# main() with missing env vars
# ---------------------------------------------------------------------------


def test_main_missing_env_vars(capsys: pytest.CaptureFixture) -> None:
    with patch.dict("os.environ", {}, clear=True):
        result = main()

    assert result == 1
    captured = capsys.readouterr()
    assert "WAZUH_API_USER" in captured.out or "WAZUH_API_PASSWORD" in captured.out


def test_main_missing_password(capsys: pytest.CaptureFixture) -> None:
    env = {"WAZUH_API_USER": "admin"}
    with patch.dict("os.environ", env, clear=True):
        result = main()

    assert result == 1
    captured = capsys.readouterr()
    assert "Missing" in captured.out
