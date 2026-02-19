import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def count_tables(example_path: Path) -> int:
    schema_dir = example_path / "schema"
    if not schema_dir.is_dir():
        return 0
    total = 0
    for sql_path in sorted(schema_dir.glob("*.sql")):
        text = sql_path.read_text(encoding="utf-8", errors="ignore")
        total += len(re.findall(r"\bCREATE\s+TABLE\b", text, flags=re.IGNORECASE))
    return total


def write_badge(path: Path, label: str, message: str, color: str, extra: dict | None = None) -> None:
    payload = {
        "schemaVersion": 1,
        "label": label,
        "message": message,
        "color": color,
    }
    if extra:
        payload.update(extra)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    examples = sorted(
        [p for p in ROOT.iterdir() if p.is_dir() and p.name.startswith("example_")]
    )

    script_map = {
        "cryptocurrency_exchange": "cryptocurrency_exchange_generator.py",
        "food_delivery": "food_delivery_generator.py",
        "gaming_platform": "gaming_platform_generator.py",
        "insurance": "insurance_generator.py",
        "hotel_chain": "hotel_chain_generator.py",
        "education": "education/generator.py",
    }

    badges_dir = ROOT / "badges"
    badges_dir.mkdir(exist_ok=True)

    example_rows = []
    foldered_count = 0
    script_count = 0

    for ex in examples:
        suffix = ex.name.split("_", 2)[-1]
        tables = count_tables(ex)

        gen_folder = ROOT / "generators" / suffix
        is_foldered = (
            gen_folder.is_dir()
            and (gen_folder / "generate.py").exists()
            and (gen_folder / "config.yaml").exists()
        )

        is_script = False
        if suffix in script_map:
            is_script = (ROOT / "generators" / script_map[suffix]).exists()

        if is_foldered:
            gen_status = "foldered"
            foldered_count += 1
        elif is_script:
            gen_status = "script"
            script_count += 1
        else:
            gen_status = "none"

        example_rows.append(
            {
                "example": ex.name,
                "tables": tables,
                "generator": gen_status,
            }
        )

    total_tables = sum(r["tables"] for r in example_rows)
    total_examples = len(example_rows)
    coverage_count = foldered_count + script_count
    coverage_pct = 0
    if total_examples:
        coverage_pct = round(coverage_count * 100 / total_examples)

    write_badge(badges_dir / "examples.json", "Examples", str(total_examples), "blue")
    write_badge(badges_dir / "tables.json", "Tables", str(total_tables), "purple")
    write_badge(
        badges_dir / "generators_foldered.json",
        "Generators (foldered)",
        str(foldered_count),
        "green",
    )
    write_badge(
        badges_dir / "generators_scripts.json",
        "Generators (scripts)",
        str(script_count),
        "yellow",
    )
    write_badge(
        badges_dir / "generators_coverage.json",
        "Generator coverage",
        f"{coverage_pct}%",
        "brightgreen" if coverage_pct >= 80 else "yellow",
    )

    (badges_dir / "examples_detail.json").write_text(
        json.dumps(example_rows, indent=2) + "\n", encoding="utf-8"
    )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
