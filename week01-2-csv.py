import csv
import logging
from pathlib import Path


logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")

ALLOWED_PRIORITIES = {"P1", "P2", "P3"}

print("!")


def validate_row(row: dict) -> list[str]:
    errors: list[str] = []
    if not row.get("id"):
        errors.append("id is empty")
    if not row.get("title"):
        errors.append("title is empty")
    if not row.get("expected"):
        errors.append("expected is empty")
    priority = row.get("priority", "").strip().upper()
    if priority and priority not in ALLOWED_PRIORITIES:
        errors.append(f"invalid priority: {priority}")
    return errors


def main() -> None:
    csv_path = Path("data.csv")
    if not csv_path.exists():
        logging.error("data.csv not found")
        return

    with csv_path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f, delimiter=";")
        total = 0
        bad = 0
        for row in reader:
            total += 1
            errs = validate_row(row)
            if errs:
                bad += 1
                logging.warning("row %s: %s", row.get("id", "<no-id>"), "; ".join(errs))
        logging.info("Checked: %d, Failed: %d", total, bad)


if __name__ == "__main__":
    main()
