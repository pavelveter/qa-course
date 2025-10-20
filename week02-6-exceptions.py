import csv
import logging
from pathlib import Path


# Настраиваем систему логирования.
# level=logging.INFO — выводим все сообщения от уровня INFO и выше (INFO, WARNING, ERROR).
# format="%(levelname)s %(message)s" — формат строки лога: уровень и текст.
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


# Функция для чтения CSV-файла и безопасной обработки ошибок.
def read_csv(path: Path):
    try:
        # Пытаемся открыть файл по указанному пути.
        # encoding="utf-8" — читаем в UTF-8, чтобы поддерживать русские символы.
        # newline="" — предотвращает добавление пустых строк при чтении.
        with path.open("r", encoding="utf-8", newline="") as f:
            # csv.DictReader читает CSV в виде списка словарей, где ключи — имена колонок.
            return list(csv.DictReader(f, delimiter=";"))

    # Если файл не найден — логируем сообщение об ошибке и возвращаем пустой список.
    except FileNotFoundError:
        logging.error("Файл %s не найден", path)
        return []

    # Ошибка кодировки — возникает, если файл не в UTF-8.
    except UnicodeDecodeError:
        logging.error("Ошибка кодировки в файле %s", path)
        return []

    # Любая другая неожиданная ошибка (например, битая структура CSV).
    # Мы выводим текст исключения, чтобы можно было понять причину.
    except Exception as e:
        logging.error("Неожиданная ошибка: %s", e)
        return []


# Основная логика: читаем CSV и сообщаем, сколько строк удалось загрузить.
rows = read_csv(Path("./data_csv_error_examples/data_structure_error.csv"))

# Выводим в лог количество загруженных строк (или 0, если файл не открылся).
logging.info(f"Загружено строк: {len(rows)}")
