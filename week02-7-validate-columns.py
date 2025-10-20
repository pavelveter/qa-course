import csv
import logging
from pathlib import Path


# Настраиваем базовую конфигурацию логирования.
# Указываем уровень INFO (будет видно INFO и WARNING) и формат сообщений.
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
log = logging.getLogger("csv-columns")  # создаём именованный логгер


# --- Проверка количества столбцов ---
def check_columns(path: Path):
    # Открываем файл и читаем все строки в список.
    # readlines() — удобен, если файл небольшой, чтобы быстро посчитать количество разделителей.
    with path.open("r", encoding="utf-8", newline="") as f:
        lines = f.readlines()

        # Первая строка — заголовок CSV.
        # Разделяем её по символу ";" и считаем количество столбцов.
        header_count = len(lines[0].split(";"))

        # Проходим по всем остальным строкам начиная со второй (нумерация с 2 для читаемого лога).
        for i, line in enumerate(lines[1:], start=2):
            count = len(line.split(";"))  # считаем разделители в каждой строке

            # Если количество столбцов отличается от заголовка — это структурная ошибка CSV.
            if count != header_count:
                log.warning(
                    f"Строка {i}: ожидалось {header_count} столбцов, найдено {count}"
                )


# --- Проверка лишних данных через restkey ---
def check_restkey(path: Path):
    # DictReader читает CSV-файл в словари.
    # restkey="_extra" — если строка содержит больше полей, чем в заголовке,
    # то все лишние значения будут помещены в ключ '_extra'.
    with path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f, delimiter=";", restkey="_extra")

        # enumerate используем для получения номера строки (начинаем со 2, т.к. заголовок — строка 1)
        for i, row in enumerate(reader, start=2):
            # Проверяем, есть ли лишние данные
            if "_extra" in row and row["_extra"]:
                log.warning(f"Строка {i}: лишние данные {row['_extra']}")


# --- Главная функция ---
def main() -> None:
    # Путь к тестовому файлу с ошибками структуры
    path = Path("./data_csv_error_examples/data_structure_error.csv")

    log.info("=== Проверка количества столбцов ===")
    check_columns(path)  # запускаем первую проверку

    log.info("=== Проверка лишних данных через restkey ===")
    check_restkey(path)  # запускаем вторую проверку


# Запуск программы только при прямом вызове (а не при импорте)
if __name__ == "__main__":
    main()
