import csv  # Модуль для чтения и записи CSV-файлов
import logging  # Модуль для логирования сообщений
from pathlib import Path  # Класс для удобной работы с путями к файлам


# Настройка системы логирования:
# level=logging.INFO — выводить все сообщения уровня INFO и выше.
# format — определяет формат лога: сначала уровень, потом само сообщение.
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")

# Множество допустимых значений приоритета (корректные варианты)
ALLOWED_PRIORITIES = {"P1", "P2", "P3"}

# Указываем путь к файлу data.csv
path = Path("data.csv")

# Открываем CSV-файл для чтения
# encoding="utf-8" — поддержка русских символов
# newline="" — чтобы не добавлялись пустые строки при чтении
with path.open("r", encoding="utf-8", newline="") as f:
    # Создаём объект DictReader, который будет возвращать строки как словари:
    # ключи — названия столбцов из первой строки CSV, значения — данные из строк.
    reader = csv.DictReader(f, delimiter=";")

    # Проходим по всем строкам файла
    for row in reader:
        # Если поле title пустое (пустая строка или None) — это ошибка
        if not row["title"]:
            logging.warning(f"Строка {row['id']}: пустое поле title")

        # Иначе, если приоритет не входит в допустимый список — тоже ошибка
        elif row["priority"] not in ALLOWED_PRIORITIES:
            logging.warning(f"Строка {row['id']}: неверный приоритет {row['priority']}")

        # Во всех остальных случаях всё в порядке — логируем как INFO
        else:
            logging.info(f"Строка {row['id']} прошла проверку")
