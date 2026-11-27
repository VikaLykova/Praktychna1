-- V7. Додавання періодичності вивезення відходів
-- Крок 1. Створення нового стовпця

ALTER TABLE airq.bin
ADD COLUMN collection_interval_days integer;

-- Крок 2. Заповнення існуючих записів

UPDATE airq.bin
SET collection_interval_days = CASE
    WHEN waste_type IN ('mixed', 'organic') THEN 1
    WHEN waste_type IN ('plastic', 'paper') THEN 2
    WHEN waste_type = 'glass' THEN 3
    ELSE 1
END;

-- Крок 3. Встановлення обов'язковості

ALTER TABLE airq.bin
ALTER COLUMN collection_interval_days SET NOT NULL;

-- Значення за замовчуванням для нових контейнерів
-- Потрібне також для завантаження seed у GitHub Actions

ALTER TABLE airq.bin
ALTER COLUMN collection_interval_days SET DEFAULT 1;

-- Перевірка допустимого інтервалу

ALTER TABLE airq.bin
ADD CONSTRAINT chk_collection_interval
CHECK (collection_interval_days BETWEEN 1 AND 30);