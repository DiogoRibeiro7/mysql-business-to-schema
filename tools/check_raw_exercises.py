import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
examples = [p for p in root.iterdir() if p.is_dir() and p.name.startswith("example_")]
missing = []
for ex in examples:
    raw_dir = ex / "raw"
    if not raw_dir.is_dir():
        missing.append(f"{ex.name}/raw")
        continue
    for fname in [
        "raw_schema.sql",
        "raw_seed.csv",
        "normalization_tasks.md",
        "solutions/normalized_schema.sql",
        "solutions/etl.sql",
    ]:
        if not (raw_dir / fname).exists():
            missing.append(f"{ex.name}/raw/{fname}")

if missing:
    print("Missing normalization exercise files:")
    for m in missing:
        print(" -", m)
    sys.exit(1)

print("Normalization exercises present for all examples")
