
SET client_encoding = 'UTF8';
SET search_path TO airq, public;

-- ПР7. Варіант 4. Контейнери відходів
-- Аналіз зміни заповнення контейнера BIN-03
-- Віконні функції AVG() OVER та LAG()

WITH measurements AS (
    SELECT
        b.bin_code,
        f.measured_at,
        ROUND(
            (100 * (1 - f.distance_cm / NULLIF(b.height_cm, 0)))::numeric,
            2
        ) AS fill_pct
    FROM fill_reading f
    JOIN bin b ON b.bin_id = f.bin_id
    WHERE b.bin_code = 'BIN-03'
      AND f.measured_at >= '2025-11-12 00:00:00+02'::timestamptz
      AND f.measured_at < '2025-11-13 00:00:00+02'::timestamptz
),
window_data AS (
    SELECT
        bin_code,
        measured_at,
        fill_pct,
        ROUND(
            AVG(fill_pct) OVER (
                PARTITION BY bin_code
                ORDER BY measured_at
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ),
            2
        ) AS avg_fill_3h,
        LAG(fill_pct) OVER (
            PARTITION BY bin_code
            ORDER BY measured_at
        ) AS previous_fill_pct
    FROM measurements
)
SELECT
    bin_code,
    TO_CHAR(
        measured_at AT TIME ZONE 'Europe/Kyiv',
        'YYYY-MM-DD HH24:MI'
    ) AS local_time,
    fill_pct,
    avg_fill_3h,
    previous_fill_pct,
    ROUND(fill_pct - previous_fill_pct, 2) AS change_pct
FROM window_data
WHERE measured_at >= '2025-11-12 10:00:00+02'::timestamptz
  AND measured_at < '2025-11-12 20:00:00+02'::timestamptz
ORDER BY measured_at;
