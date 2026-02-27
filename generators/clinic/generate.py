#!/usr/bin/env python3
"""
Clinic dataset generator.

Reads a JSON-compatible YAML config file and writes CSVs plus an optional SQL seed file.
The generated data is deterministic for a given seed and respects FK relationships.
"""

from __future__ import annotations

import argparse
import csv
import json
import random
from dataclasses import dataclass
from datetime import date, datetime, time, timedelta
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple


@dataclass(frozen=True)
class Counts:
    """Record counts for each entity."""

    patients: int
    doctors: int
    appointments: int
    invoices: int
    payments: int


@dataclass(frozen=True)
class DateRanges:
    """Date ranges for generated records (inclusive)."""

    appointments_start: date
    appointments_end: date
    invoices_start: date
    invoices_end: date
    payments_start: date
    payments_end: date


@dataclass(frozen=True)
class Config:
    """Validated config values."""

    seed: int
    output_dir: Path
    counts: Counts
    date_ranges: DateRanges


def _parse_date(value: str, field_name: str) -> date:
    """Parse a YYYY-MM-DD string into a date with helpful errors."""

    try:
        return datetime.strptime(value, "%Y-%m-%d").date()
    except ValueError as exc:
        raise ValueError(f"Invalid date for {field_name}: {value}") from exc


def load_config(path: Path) -> Config:
    """Load and validate the config file."""

    if not path.exists():
        raise FileNotFoundError(f"Config not found: {path}")

    raw_text = path.read_text(encoding="utf-8")

    # Prefer PyYAML if available; otherwise parse JSON (YAML-compatible).
    data: Dict[str, object]
    try:
        import yaml  # type: ignore

        data = yaml.safe_load(raw_text) or {}
    except Exception:
        data = json.loads(raw_text)

    if not isinstance(data, dict):
        raise ValueError("Config must be a mapping at the top level.")

    seed = int(data.get("seed", 42))
    output_dir = Path(data.get("output_dir", "generators/clinic/output"))

    counts_raw = data.get("counts", {})
    if not isinstance(counts_raw, dict):
        raise ValueError("counts must be a mapping.")
    counts = Counts(
        patients=int(counts_raw.get("patients", 30)),
        doctors=int(counts_raw.get("doctors", 10)),
        appointments=int(counts_raw.get("appointments", 200)),
        invoices=int(counts_raw.get("invoices", 120)),
        payments=int(counts_raw.get("payments", 150)),
    )

    date_ranges_raw = data.get("date_ranges", {})
    if not isinstance(date_ranges_raw, dict):
        raise ValueError("date_ranges must be a mapping.")

    date_ranges = DateRanges(
        appointments_start=_parse_date(
            str(date_ranges_raw["appointments_start"]), "appointments_start"
        ),
        appointments_end=_parse_date(
            str(date_ranges_raw["appointments_end"]), "appointments_end"
        ),
        invoices_start=_parse_date(
            str(date_ranges_raw["invoices_start"]), "invoices_start"
        ),
        invoices_end=_parse_date(str(date_ranges_raw["invoices_end"]), "invoices_end"),
        payments_start=_parse_date(
            str(date_ranges_raw["payments_start"]), "payments_start"
        ),
        payments_end=_parse_date(str(date_ranges_raw["payments_end"]), "payments_end"),
    )

    # Basic validation
    if counts.patients <= 0 or counts.doctors <= 0:
        raise ValueError("patients and doctors must be > 0.")
    if counts.appointments <= 0:
        raise ValueError("appointments must be > 0.")
    if counts.invoices <= 0 or counts.payments <= 0:
        raise ValueError("invoices and payments must be > 0.")

    if date_ranges.appointments_start > date_ranges.appointments_end:
        raise ValueError("appointments_start must be <= appointments_end.")
    if date_ranges.invoices_start > date_ranges.invoices_end:
        raise ValueError("invoices_start must be <= invoices_end.")
    if date_ranges.payments_start > date_ranges.payments_end:
        raise ValueError("payments_start must be <= payments_end.")

    return Config(
        seed=seed, output_dir=output_dir, counts=counts, date_ranges=date_ranges
    )


def _daterange(start: date, end: date) -> List[date]:
    """Return a list of dates from start to end inclusive."""

    days = (end - start).days
    return [start + timedelta(days=i) for i in range(days + 1)]


def _pick_date(rng: random.Random, start: date, end: date) -> date:
    """Pick a random date in the inclusive range."""

    days = (end - start).days
    return start + timedelta(days=rng.randint(0, days))


def _next_slot(current: datetime) -> datetime:
    """Move to the next time slot (30-minute blocks from 09:00 to 17:00)."""

    new_time = current + timedelta(minutes=30)
    if new_time.time() >= time(17, 0):
        # Move to next day at 09:00
        new_time = datetime.combine(new_time.date() + timedelta(days=1), time(9, 0))
    return new_time


def _start_of_day(date_value: date) -> datetime:
    """Return a datetime at 09:00 for the given date."""

    return datetime.combine(date_value, time(9, 0))


def generate_patients(rng: random.Random, count: int) -> List[Dict[str, object]]:
    """Generate patient rows."""

    patients: List[Dict[str, object]] = []
    # rng is kept for future variability while keeping a stable signature
    _ = rng
    for i in range(1, count + 1):
        year = 1965 + (i % 35)
        month = (i % 12) + 1
        day = (i % 28) + 1
        patients.append(
            {
                "patient_id": i,
                "nif": f"PT{10000000 + i}",
                "first_name": f"Patient{i}",
                "last_name": f"Last{i}",
                "date_of_birth": f"{year:04d}-{month:02d}-{day:02d}",
                "phone": f"+351910000{100 + i:03d}",
                "email": f"patient{i}@example.com",
                "created_at": "2025-01-15 09:00:00",
                "status": "inactive" if i % 7 == 0 else "active",
            }
        )
    return patients


def generate_doctors(rng: random.Random, count: int) -> List[Dict[str, object]]:
    """Generate doctor rows."""

    doctors: List[Dict[str, object]] = []
    for i in range(1, count + 1):
        active_to: Optional[str] = None
        if i % 5 == 0:
            active_to = "2025-06-30"
        doctors.append(
            {
                "doctor_id": i,
                "license_number": f"LIC{i:04d}",
                "first_name": f"Doctor{i}",
                "last_name": f"Last{i}",
                "email": f"doctor{i}@example.com",
                "phone": f"+351920000{100 + i:03d}",
                "active_from": "2020-01-01",
                "active_to": active_to,
            }
        )
    return doctors


def generate_appointments(
    rng: random.Random,
    count: int,
    patient_count: int,
    doctor_count: int,
    start: date,
    end: date,
) -> List[Dict[str, object]]:
    """Generate appointment rows with non-overlapping slots per doctor."""

    appointments: List[Dict[str, object]] = []
    start_dates = _daterange(start, end)

    # Track next available slot per doctor to avoid overlaps.
    next_slots: Dict[int, datetime] = {
        doctor_id: _start_of_day(rng.choice(start_dates))
        for doctor_id in range(1, doctor_count + 1)
    }

    for i in range(1, count + 1):
        doctor_id = (i % doctor_count) + 1
        patient_id = rng.randint(1, patient_count)

        start_time = next_slots[doctor_id]
        end_time = start_time + timedelta(minutes=30)
        next_slots[doctor_id] = _next_slot(start_time)

        status = "completed"
        cancel_reason = None
        no_show_reason = None
        if i % 13 == 0:
            status = "cancelled"
            cancel_reason = "Patient requested"
        elif i % 17 == 0:
            status = "no_show"
            no_show_reason = "No show"

        created_at = (start_time - timedelta(days=7)).strftime("%Y-%m-%d %H:%M:%S")
        updated_at = (start_time - timedelta(days=1)).strftime("%Y-%m-%d %H:%M:%S")

        # If we run past the configured date range, wrap back to start.
        if start_time.date() > end:
            reset_date = rng.choice(start_dates)
            start_time = _start_of_day(reset_date)
            end_time = start_time + timedelta(minutes=30)
            next_slots[doctor_id] = _next_slot(start_time)

        appointments.append(
            {
                "appointment_id": i,
                "patient_id": patient_id,
                "doctor_id": doctor_id,
                "start_time": start_time.strftime("%Y-%m-%d %H:%M:%S"),
                "end_time": end_time.strftime("%Y-%m-%d %H:%M:%S"),
                "status": status,
                "cancel_reason": cancel_reason,
                "no_show_reason": no_show_reason,
                "created_at": created_at,
                "updated_at": updated_at,
            }
        )
    return appointments


def generate_invoices(
    rng: random.Random,
    count: int,
    patient_count: int,
    start: date,
    end: date,
) -> List[Dict[str, object]]:
    """Generate invoice rows."""

    invoices: List[Dict[str, object]] = []
    for i in range(1, count + 1):
        issue_date = _pick_date(rng, start, end)
        total_amount = round(60 + rng.randint(0, 12) * 10, 2)
        status = rng.choice(["open", "partially_paid", "paid"])
        invoices.append(
            {
                "invoice_id": i,
                "patient_id": rng.randint(1, patient_count),
                "invoice_number": f"INV-{issue_date.year}-{i:04d}",
                "issued_at": datetime.combine(issue_date, time(12, 0)).strftime(
                    "%Y-%m-%d %H:%M:%S"
                ),
                "status": status,
                "total_amount": total_amount,
            }
        )
    return invoices


def generate_payments(
    rng: random.Random,
    count: int,
    patient_count: int,
    start: date,
    end: date,
) -> List[Dict[str, object]]:
    """Generate payment rows."""

    payments: List[Dict[str, object]] = []
    for i in range(1, count + 1):
        pay_date = _pick_date(rng, start, end)
        payments.append(
            {
                "payment_id": i,
                "patient_id": rng.randint(1, patient_count),
                "payment_date": datetime.combine(pay_date, time(15, 30)).strftime(
                    "%Y-%m-%d %H:%M:%S"
                ),
                "method": "card" if i % 2 == 0 else "cash",
                "reference": f"PAY-{i:05d}",
                "amount": round(20 + (i % 5) * 10, 2),
            }
        )
    return payments


def write_csv(
    path: Path, rows: Iterable[Dict[str, object]], fieldnames: List[str]
) -> None:
    """Write CSV to disk with headers."""

    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def write_seed_sql(
    path: Path,
    patients: List[Dict[str, object]],
    doctors: List[Dict[str, object]],
    appointments: List[Dict[str, object]],
    invoices: List[Dict[str, object]],
    payments: List[Dict[str, object]],
) -> None:
    """Write SQL insert statements for generated rows."""

    path.parent.mkdir(parents=True, exist_ok=True)
    lines: List[str] = ["USE clinic;", "", "START TRANSACTION;", ""]

    def _insert(table: str, cols: List[str], rows: List[Dict[str, object]]) -> None:
        values = []
        for row in rows:
            values.append(
                "("
                + ", ".join(
                    (
                        "NULL"
                        if row.get(col) is None
                        else (
                            f"'{row[col]}'"
                            if isinstance(row.get(col), str)
                            else str(row.get(col))
                        )
                    )
                    for col in cols
                )
                + ")"
            )
        lines.append(f"INSERT INTO {table} ({', '.join(cols)}) VALUES")
        lines.append(",\n".join(values) + ";")
        lines.append("")

    _insert(
        "patients",
        [
            "patient_id",
            "nif",
            "first_name",
            "last_name",
            "date_of_birth",
            "phone",
            "email",
            "created_at",
            "status",
        ],
        patients,
    )
    _insert(
        "doctors",
        [
            "doctor_id",
            "license_number",
            "first_name",
            "last_name",
            "email",
            "phone",
            "active_from",
            "active_to",
        ],
        doctors,
    )
    _insert(
        "appointments",
        [
            "appointment_id",
            "patient_id",
            "doctor_id",
            "start_time",
            "end_time",
            "status",
            "cancel_reason",
            "no_show_reason",
            "created_at",
            "updated_at",
        ],
        appointments,
    )
    _insert(
        "invoices",
        [
            "invoice_id",
            "patient_id",
            "invoice_number",
            "issued_at",
            "status",
            "total_amount",
        ],
        invoices,
    )
    _insert(
        "payments",
        ["payment_id", "patient_id", "payment_date", "method", "reference", "amount"],
        payments,
    )

    lines.append("COMMIT;")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    """CLI entrypoint."""

    parser = argparse.ArgumentParser(description="Generate clinic datasets.")
    parser.add_argument(
        "--config", default="config.yaml", help="Path to config YAML/JSON file."
    )
    args = parser.parse_args()

    config_path = Path(args.config)
    config = load_config(config_path)
    rng = random.Random(config.seed)

    patients = generate_patients(rng, config.counts.patients)
    doctors = generate_doctors(rng, config.counts.doctors)
    appointments = generate_appointments(
        rng,
        config.counts.appointments,
        config.counts.patients,
        config.counts.doctors,
        config.date_ranges.appointments_start,
        config.date_ranges.appointments_end,
    )
    invoices = generate_invoices(
        rng,
        config.counts.invoices,
        config.counts.patients,
        config.date_ranges.invoices_start,
        config.date_ranges.invoices_end,
    )
    payments = generate_payments(
        rng,
        config.counts.payments,
        config.counts.patients,
        config.date_ranges.payments_start,
        config.date_ranges.payments_end,
    )

    output_dir = config.output_dir
    if not output_dir.is_absolute():
        # Resolve relative output paths from the config file location.
        output_dir = (config_path.parent / output_dir).resolve()

    write_csv(
        output_dir / "patients.csv",
        patients,
        [
            "patient_id",
            "nif",
            "first_name",
            "last_name",
            "date_of_birth",
            "phone",
            "email",
            "created_at",
            "status",
        ],
    )
    write_csv(
        output_dir / "doctors.csv",
        doctors,
        [
            "doctor_id",
            "license_number",
            "first_name",
            "last_name",
            "email",
            "phone",
            "active_from",
            "active_to",
        ],
    )
    write_csv(
        output_dir / "appointments.csv",
        appointments,
        [
            "appointment_id",
            "patient_id",
            "doctor_id",
            "start_time",
            "end_time",
            "status",
            "cancel_reason",
            "no_show_reason",
            "created_at",
            "updated_at",
        ],
    )
    write_csv(
        output_dir / "invoices.csv",
        invoices,
        [
            "invoice_id",
            "patient_id",
            "invoice_number",
            "issued_at",
            "status",
            "total_amount",
        ],
    )
    write_csv(
        output_dir / "payments.csv",
        payments,
        ["payment_id", "patient_id", "payment_date", "method", "reference", "amount"],
    )

    write_seed_sql(
        output_dir / "seed_generated.sql",
        patients,
        doctors,
        appointments,
        invoices,
        payments,
    )

    print(f"Wrote data to {output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
