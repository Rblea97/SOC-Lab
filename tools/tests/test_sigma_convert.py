from pathlib import Path

from sigma_convert import convert_to_wazuh_xml, parse_sigma_rule, validate_wazuh_rule


def test_parse_convert_validate(tmp_path: Path) -> None:
    sigma_file = tmp_path / "rule.yml"
    sigma_file.write_text(
        """
title: SSH brute force
description: Detect repeated failed ssh auth attempts
id: 9f43d24e-72b5-4af6-b6c7-2276f6edfe10
logsource:
  product: linux
  service: sshd
detection:
  selection:
    message|contains:
      - Failed password
      - authentication failure
  condition: selection
tags:
  - attack.t1110.001
""".strip()
    )

    rule = parse_sigma_rule(sigma_file)
    xml_text = convert_to_wazuh_xml(rule, base_id=100700)

    assert rule.title == "SSH brute force"
    assert rule.mitre_id == "T1110.001"
    assert '<rule id="100700"' in xml_text
    assert validate_wazuh_rule(xml_text) is True


def test_no_mitre_tags(tmp_path: Path) -> None:
    sigma_file = tmp_path / "rule.yml"
    sigma_file.write_text(
        """
title: Generic syslog anomaly
description: Detect suspicious syslog entries
id: aaaaaaaa-0000-0000-0000-000000000001
logsource:
  product: linux
detection:
  selection:
    message|contains:
      - suspicious
  condition: selection
""".strip()
    )

    rule = parse_sigma_rule(sigma_file)
    xml_text = convert_to_wazuh_xml(rule, base_id=100701)

    assert rule.mitre_id is None
    assert "<mitre>" not in xml_text
    assert validate_wazuh_rule(xml_text) is True
