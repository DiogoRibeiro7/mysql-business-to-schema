#!/usr/bin/env python3
"""
Simple Generator Benchmark - Tests all generators quickly
"""

import os
import sys
import time
import subprocess
from pathlib import Path
from datetime import datetime


def benchmark_generator(gen_path, timeout=30):
    """Run a generator and measure its performance"""
    gen_name = gen_path.name
    test_file = gen_path / "test_generator.py"

    if not test_file.exists():
        return None

    start = time.time()

    try:
        result = subprocess.run(
            [sys.executable, str(test_file)],
            cwd=str(gen_path),
            capture_output=True,
            text=True,
            timeout=timeout,
        )

        duration = time.time() - start

        # Parse output for generated records
        rows = 0
        for line in result.stdout.split("\n"):
            if "Generated" in line or "Generating" in line:
                # Try to find numbers in the line
                parts = line.split()
                for part in parts:
                    if part.isdigit():
                        num = int(part)
                        if 10 < num < 100000:  # Reasonable row count range
                            rows = max(rows, num)

        return {
            "name": gen_name,
            "duration": round(duration, 2),
            "rows": rows,
            "success": result.returncode == 0,
            "rows_per_sec": round(rows / duration, 2) if duration > 0 else 0,
        }

    except subprocess.TimeoutExpired:
        return {
            "name": gen_name,
            "duration": timeout,
            "rows": 0,
            "success": False,
            "error": "Timeout",
        }
    except Exception as e:
        return {
            "name": gen_name,
            "duration": 0,
            "rows": 0,
            "success": False,
            "error": str(e),
        }


def main():
    # Get project root
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    generators_dir = project_root / "generators"

    # Find all generators
    generators = []
    for item in generators_dir.iterdir():
        if item.is_dir() and not item.name.startswith("_"):
            if (item / "test_generator.py").exists():
                generators.append(item)

    generators = sorted(generators)

    print("MySQL Business-to-Schema - Quick Generator Benchmark")
    print("=" * 60)
    print(f"Found {len(generators)} generators")
    print(f"Timeout: 30 seconds per generator")
    print("=" * 60)
    print()

    results = []
    start_time = datetime.now()

    # Run benchmarks
    for i, gen_path in enumerate(generators, 1):
        print(
            f"[{i}/{len(generators)}] Testing {gen_path.name}...", end=" ", flush=True
        )

        result = benchmark_generator(gen_path)

        if result:
            results.append(result)
            if result["success"]:
                print(f"[OK] {result['duration']}s, {result['rows']} rows")
            else:
                error = result.get("error", "Failed")
                print(f"[FAIL] {error}")
        else:
            print("[SKIP] No test generator")

    end_time = datetime.now()
    total_duration = (end_time - start_time).total_seconds()

    # Print summary
    print()
    print("=" * 60)
    print("Summary")
    print("=" * 60)

    successful = [r for r in results if r["success"]]
    failed = [r for r in results if not r["success"]]

    print(f"Total: {len(results)} generators tested")
    print(f"Successful: {len(successful)}")
    print(f"Failed: {len(failed)}")
    print(f"Total Time: {total_duration:.2f}s")
    print()

    if successful:
        print("Top Performers (by rows/sec):")
        print("-" * 40)
        sorted_results = sorted(
            successful, key=lambda x: x["rows_per_sec"], reverse=True
        )
        for i, r in enumerate(sorted_results[:5], 1):
            print(
                f"{i}. {r['name']}: {r['rows_per_sec']} rows/sec ({r['rows']} rows in {r['duration']}s)"
            )

        print()
        print("Statistics:")
        total_rows = sum(r["rows"] for r in successful)
        avg_duration = sum(r["duration"] for r in successful) / len(successful)
        print(f"  Total Rows Generated: {total_rows:,}")
        print(f"  Average Duration: {avg_duration:.2f}s")

    if failed:
        print()
        print("Failed Generators:")
        for r in failed:
            print(f"  - {r['name']}: {r.get('error', 'Unknown error')}")

    # Save results
    output_dir = project_root / "benchmark_results"
    output_dir.mkdir(exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = output_dir / f"quick_benchmark_{timestamp}.txt"

    with open(output_file, "w") as f:
        f.write("MySQL Business-to-Schema - Generator Benchmark Results\n")
        f.write(f"Date: {datetime.now().isoformat()}\n")
        f.write(f"Duration: {total_duration:.2f}s\n")
        f.write("=" * 60 + "\n\n")

        f.write("Results:\n")
        for r in results:
            f.write(
                f"  {r['name']}: {'SUCCESS' if r['success'] else 'FAIL'} - {r['duration']}s, {r['rows']} rows\n"
            )

    print()
    print(f"Results saved to: {output_file}")


if __name__ == "__main__":
    main()
