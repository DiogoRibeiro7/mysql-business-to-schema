#!/usr/bin/env python3
"""
Generate a lightweight consolidated security report from common artifacts.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except FileNotFoundError:
        return ""


def load_json(path: Path) -> Any:
    try:
        return json.loads(read_text(path))
    except json.JSONDecodeError:
        return None


def summarize_reports(report_dir: Path) -> List[str]:
    summaries: List[str] = []

    bandit = report_dir / "bandit_report.json"
    if bandit.exists():
        data = load_json(bandit) or {}
        results = data.get("results", [])
        summaries.append(f"Bandit findings: {len(results)}")

    safety = report_dir / "safety_report.json"
    if safety.exists():
        data = load_json(safety) or {}
        vulns = data.get("vulnerabilities", []) or data.get("vulns", [])
        summaries.append(f"Safety findings: {len(vulns)}")

    pip_audit = report_dir / "pip_audit.json"
    if pip_audit.exists():
        data = load_json(pip_audit) or {}
        vulns = data.get("vulnerabilities", [])
        summaries.append(f"Pip-audit findings: {len(vulns)}")

    dep_check = report_dir / "dependency-check-report.json"
    if dep_check.exists():
        data = load_json(dep_check) or {}
        deps = data.get("dependencies", [])
        summaries.append(f"OWASP Dependency-Check scanned: {len(deps)} dependencies")

    if not summaries:
        summaries.append("No security artifacts found.")

    return summaries


def render_html(title: str, lines: List[str]) -> str:
    items = "\n".join(f"<li>{line}</li>" for line in lines)
    return f"""<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>{title}</title>
    <style>
      body {{ font-family: Arial, sans-serif; margin: 2rem; }}
      h1 {{ margin-bottom: 1rem; }}
      ul {{ line-height: 1.6; }}
      code {{ background: #f4f4f4; padding: 0.1rem 0.3rem; border-radius: 3px; }}
    </style>
  </head>
  <body>
    <h1>{title}</h1>
    <ul>
      {items}
    </ul>
  </body>
</html>
"""


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate security report")
    parser.add_argument("--output", required=True, help="Output HTML file")
    parser.add_argument("--reports-dir", default="reports", help="Reports directory")
    args = parser.parse_args()

    report_dir = Path(args.reports_dir)
    lines = summarize_reports(report_dir)
    html = render_html("Security Scan Summary", lines)

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(html, encoding="utf-8")


if __name__ == "__main__":
    main()
