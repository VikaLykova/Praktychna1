-- V6. Частковий індекс для пошуку критично заповнених контейнерів

CREATE INDEX IF NOT EXISTS fill_reading_critical_time_idx
ON airq.fill_reading (measured_at)
WHERE fill_pct >= 95;