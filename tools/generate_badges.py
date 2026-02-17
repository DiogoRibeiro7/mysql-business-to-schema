#!/usr/bin/env python3
"""
Generate status badges for README
Creates shield.io style badges for repository statistics
"""

import json
import os
import sys
from pathlib import Path
from urllib.parse import quote

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.append(str(PROJECT_ROOT))

class BadgeGenerator:
    def __init__(self):
        self.project_root = PROJECT_ROOT
        self.badges = []

    def generate_all(self):
        """Generate all badges"""
        print("Generating README badges...")
        print("-" * 40)

        # Count statistics
        examples = len(list(self.project_root.glob("example_*")))
        generators = len([d for d in (self.project_root / "generators").iterdir()
                         if d.is_dir() and not d.name.startswith('__')])

        # Calculate coverage
        generator_coverage = (generators / examples * 100) if examples > 0 else 0

        # Generate badges
        self.add_badge("Examples", str(examples), "blue")
        self.add_badge("Generators", f"{generators}/{examples}", "green" if generator_coverage >= 90 else "yellow")
        self.add_badge("Coverage", f"{generator_coverage:.0f}%",
                      "success" if generator_coverage >= 90 else "yellow")
        self.add_badge("MySQL", "8.0+", "orange")
        self.add_badge("Python", "3.8+", "blue")
        self.add_badge("License", "MIT", "green")

        # Count total tables
        total_tables = self.count_total_tables()
        self.add_badge("Total Tables", str(total_tables), "purple")

        # Check health score
        health_score = self.get_health_score()
        if health_score:
            color = "success" if health_score >= 90 else "green" if health_score >= 75 else "yellow"
            self.add_badge("Health", f"{health_score:.0f}%", color)

        # Generate badge markdown
        self.generate_markdown()
        self.generate_html()

    def add_badge(self, label, message, color):
        """Add a badge to the list"""
        badge_url = f"https://img.shields.io/badge/{quote(label)}-{quote(message)}-{color}"
        self.badges.append({
            "label": label,
            "message": message,
            "color": color,
            "url": badge_url
        })
        print(f"  [OK] {label}: {message}")

    def count_total_tables(self):
        """Count total tables across all examples"""
        total = 0
        table_counts = {
            "example_01_clinic": 9,
            "example_02_iot_bins": 15,
            "example_03_smart_energy": 18,
            "example_04_ecommerce": 21,
            "example_05_industrial_iot": 20,
            "example_06_smart_agriculture": 21,
            "example_07_fleet_management": 22,
            "example_08_healthcare_iot": 24,
            "example_09_streaming_ml": 29,
            "example_10_fintech": 26,
            "example_11_social_media": 25,
            "example_12_real_estate": 29,
            "example_13_event_ticketing": 26,
            "example_14_logistics": 24,
            "example_15_education": 33
        }

        for example_dir in self.project_root.glob("example_*"):
            if example_dir.name in table_counts:
                total += table_counts[example_dir.name]

        return total

    def get_health_score(self):
        """Get health score from health check report"""
        report_file = self.project_root / "health_check_report.json"
        if report_file.exists():
            try:
                with open(report_file, 'r') as f:
                    data = json.load(f)
                    # Calculate score based on passed/failed
                    passed = data.get("overall", {}).get("passed", 0)
                    failed = data.get("overall", {}).get("failed", 0)
                    total = passed + failed
                    if total > 0:
                        return (passed / total) * 100
            except:
                pass
        return None

    def generate_markdown(self):
        """Generate markdown for badges"""
        print("\n" + "="*60)
        print("Badge Markdown for README.md:")
        print("="*60)
        print("\nCopy and paste this at the top of your README.md:\n")

        # Individual badges
        markdown = "<!-- Status Badges -->\n"
        markdown += "<p align=\"center\">\n"
        for badge in self.badges:
            markdown += f"  <img src=\"{badge['url']}\" alt=\"{badge['label']}: {badge['message']}\" />\n"
        markdown += "</p>\n"

        print(markdown)

        # Also save to file
        output_file = self.project_root / "badges.md"
        with open(output_file, 'w') as f:
            f.write(markdown)

        print(f"Badges saved to: badges.md")

    def generate_html(self):
        """Generate HTML version of badges"""
        html = "<!-- Status Badges HTML -->\n"
        html += "<div align=\"center\">\n"
        for badge in self.badges:
            html += f'  <img src="{badge["url"]}" alt="{badge["label"]}: {badge["message"]}" style="margin: 5px;" />\n'
        html += "</div>\n"

        # Save HTML version
        output_file = self.project_root / "badges.html"
        with open(output_file, 'w') as f:
            f.write(html)

        print(f"HTML version saved to: badges.html")

    def generate_shield_json(self):
        """Generate shield.io JSON endpoint file"""
        shields = []
        for badge in self.badges:
            shields.append({
                "schemaVersion": 1,
                "label": badge["label"],
                "message": badge["message"],
                "color": badge["color"]
            })

        output_file = self.project_root / "shields.json"
        with open(output_file, 'w') as f:
            json.dump(shields, f, indent=2)

        print(f"Shields JSON saved to: shields.json")

def main():
    """Generate badges"""
    generator = BadgeGenerator()
    generator.generate_all()

    print("\n" + "="*60)
    print("[SUCCESS] Badges generated successfully!")
    print("="*60)
    print("\nNext steps:")
    print("1. Copy the badge markdown from badges.md")
    print("2. Paste it at the top of your README.md")
    print("3. Commit and push to see the badges in action!")

if __name__ == "__main__":
    main()