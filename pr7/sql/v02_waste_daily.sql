
SET client_encoding = 'UTF8';
SET search_path TO airq, public;

-- ПР7. Варіант 4. Контейнери відходів
-- Добова статистика заповнення контейнерів
-- Аналіз середнього, максимального та критичного рівня

WITH daily_data AS (
    SELECT
        (f.measured_at AT TIME ZONE 'Europe/Kyiv')::date AS local_day,
        b.bin_id,
        b.bin_code,
        ROUND(
            (100 * (1 - f.distance_cm / NULLIF(b.height_cm, 0)))::numeric,
            2
        ) AS fill_pct
    FROM fill_reading f
    JOIN bin b ON b.bin_id = f.bin_id
    WHERE f.measured_at >= '2025-11-01 00:00:00+02'
      AND f.measured_at < '2025-12-01 00:00:00+02'
      AND b.is_active = true
)
SELECT
    local_day AS measurement_date,
    COUNT(DISTINCT bin_id) AS total_bins,
    COUNT(*) AS total_readings,
    ROUND(AVG(fill_pct), 2) AS avg_fill_pct,
    ROUND(MAX(fill_pct), 2) AS max_fill_pct,
    COUNT(*) FILTER (
        WHERE fill_pct >= 80
    ) AS readings_over_80,
    COUNT(*) FILTER (
        WHERE fill_pct >= 95
    ) AS readings_over_95,
    COUNT(DISTINCT bin_id) FILTER (
        WHERE fill_pct >= 95
    ) AS critical_bins
FROM daily_data
WHERE local_day BETWEEN '2025-11-10' AND '2025-11-16'
GROUP BY local_day
ORDER BY local_day;
