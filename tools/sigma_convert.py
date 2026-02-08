"""Convert a small Sigma subset to Wazuh XML."""

from __future__ import annotations

import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path

import yaml


@dataclass(slots=True)
class SigmaRule:
    title: str
    rule_id: str
    description: str
    product: str
    service: str | None
    keywords: list[str]
    mitre_id: str | None


def parse_sigma_rule(path: Path) -> SigmaRule:
    """Parse a Sigma YAML file into a normalized dataclass."""
    data = yaml.safe_load(path.read_text())
    detection = data.get("detection", {})
    selection = detection.get("selection", {})

    keywords: list[str] = []
    for value in selection.values():
        if isinstance(value, str):
            keywords.append(value)
        elif isinstance(value, list):
            keywords.extend(str(v) for v in value)

    tags: list[str] = data.get("tags", [])
    mitre_id: str | None = None
    for tag in tags:
        tag_str = str(tag)
        if tag_str.startswith("attack.t"):
            mitre_id = tag_str.split("attack.", maxsplit=1)[1].upper()
            break

    return SigmaRule(
        title=str(data.get("title", "Untitled Sigma Rule")),
        rule_id=str(data.get("id", "sigma-generated")),
        description=str(data.get("description", "")),
        product=str(data.get("logsource", {}).get("product", "linux")),
        service=data.get("logsource", {}).get("service"),
        keywords=keywords,
        mitre_id=mitre_id,
    )


def convert_to_wazuh_xml(rule: SigmaRule, base_id: int) -> str:
    """Convert SigmaRule to a simple Wazuh local rule XML string."""
    match_expr = "|".join(k.replace("|", "") for k in rule.keywords if k)
    if not match_expr:
        match_expr = rule.title

    mitre_block = ""
    if rule.mitre_id:
        mitre_block = f"\n    <mitre>\n      <id>{rule.mitre_id}</id>\n    </mitre>"

    return (
        '<group name="local,sigma,">\n'
        f'  <rule id="{base_id}" level="10">\n'
        "    <if_group>syslog</if_group>\n"
        f"    <match>{match_expr}</match>\n"
        f"    <description>{rule.title}: {rule.description}</description>"
        f"{mitre_block}\n"
        "  </rule>\n"
        "</group>\n"
    )


def validate_wazuh_rule(xml_str: str) -> bool:
    """Return True when xml_str is parseable XML."""
    try:
        ET.fromstring(xml_str)
    except ET.ParseError:
        return False
    return True


def main() -> int:
    """CLI entrypoint."""
    if len(sys.argv) < 2:
        print("Usage: python sigma_convert.py <sigma-rule.yml> [base_id]")
        return 1

    source = Path(sys.argv[1])
    base_id = int(sys.argv[2]) if len(sys.argv) > 2 else 100500

    sigma_rule = parse_sigma_rule(source)
    xml_text = convert_to_wazuh_xml(sigma_rule, base_id)
    if not validate_wazuh_rule(xml_text):
        print("Generated XML is invalid")
        return 2

    print(xml_text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
