import csv
import logging
from pathlib import Path


# Настройка логирования
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


# Проверка одной строки CSV
def validate_row(row: dict) -> list[str]:
    errors = []
    if not row["title"]:
        errors.append("title пустой")
    if not row["expected"]:
        errors.append("expected пустой")
    return errors


# Пути к файлам
src = Path("data.csv")
dst = Path("report.csv")

# Открываем исходный файл и создаём отчёт
with src.open("r", encoding="utf-8", newline="") as f_in, dst.open(
    "w", encoding="utf-8", newline=""
) as f_out:
    # Чтение и запись CSV с точкой с запятой как разделителем
    reader = csv.DictReader(f_in, delimiter=";")
    writer = csv.DictWriter(f_out, fieldnames=["id", "errors"], delimiter=";")
    writer.writeheader()

    total = bad = 0
    for row in reader:
        total += 1
        errs = validate_row(row)
        if errs:
            bad += 1
            writer.writerow({"id": row["id"], "errors": "; ".join(errs)})

# Итоговый лог
logging.info(f"Отчёт сохранён: {dst}, ошибок {bad} из {total}")
