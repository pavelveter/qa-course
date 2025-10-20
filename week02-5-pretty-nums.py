import csv
import logging
from pathlib import Path


# Настраиваем логирование
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
log = logging.getLogger("csv-check")

# Разрешённые приоритеты
ALLOWED_PRIORITIES = {"P1", "P2", "P3"}

# Счётчики
total = bad = 0
errors_by_type = {"title": 0, "priority": 0, "expected": 0}

# Читаем CSV-файл
with Path("data.csv").open("r", encoding="utf-8", newline="") as f:
    reader = csv.DictReader(f, delimiter=";")
    for row in reader:
        total += 1
        errors = []

        if not row["title"]:
            errors.append("title пустой")
            errors_by_type["title"] += 1

        if row["priority"] not in ALLOWED_PRIORITIES:
            errors.append("priority неверный")
            errors_by_type["priority"] += 1

        if not row["expected"]:
            errors.append("expected пустой")
            errors_by_type["expected"] += 1

        if errors:
            bad += 1
            log.warning(f"Строка {row['id']}: {', '.join(errors)}")

# Итоги
rate = bad / total * 100 if total else 0
passed = total - bad

# Форматированный вывод итогов
print()
print("=" * 40)
print(f"Проверено: {total}")
print(f"Ошибок:    {bad} ({rate:.1f}%)")
print(f"Пройдено:  {passed}")
print("=" * 40)

# Таблица по типам ошибок
print(f"{'Столбец':<12} | {'Ошибок':>8}")
print("-" * 25)
for col, count in errors_by_type.items():
    print(f"{col:<12} | {count:>8}")
print("=" * 40)
