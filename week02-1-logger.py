import logging


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[
        logging.StreamHandler(),  # на экран
        logging.FileHandler("app.log"),  # в файл
    ],
)
logger = logging.getLogger(__name__)
user = "alice"
print(f"User {user} logged in")  # разовый вывод
logger.info("User %s logged in", user)  # управляемый лог
logger.warning("User %s make something strange", user)  # пример уровня WARNING
logger.error("User %s failed auth", user)  # пример уровня ERROR
