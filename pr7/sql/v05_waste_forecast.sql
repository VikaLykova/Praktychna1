
SET client_encoding = 'UTF8';
SET search_path TO airq, public;

-- ПР7. Варіант 4. Прогноз переповнення контейнерів.
-- F = 100 * (1 - distance_cm / height_cm)
-- r = regr_slope(F, time)
-- t100 = (100 - F) / r
-- Шукаємо контейнери, які можуть заповнитися менш ніж за 4 години.

WITH observations AS (
    SELECT
        b.bin_id,
        b.bin_code,
        f.measured_at,
        ROUND(
            (100.0 * (
                1 - f.distance_cm / NULLIF(b.height_cm, 0)
            ))::numeric,
            2
        ) AS fill_pct
    FROM bin b
    JOIN fill_reading f ON f.bin_id = b.bin_id
    WHERE b.is_active = true
      AND f.measured_at >=
          '2025-11-12 12:00:00+02'::timestamptz
      AND f.measured_at <=
          '2025-11-12 14:00:00+02'::timestamptz
),
speed AS (
    SELECT
        bin_id,
        bin_code,
        measured_at,
        fill_pct,
        COUNT(*) OVER (
            PARTITION BY bin_id
            ORDER BY measured_at
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS points_count,
        REGR_SLOPE(
            fill_pct::double precision,
            (
                EXTRACT(EPOCH FROM measured_at) / 3600.0
            )::double precision
        ) OVER (
            PARTITION BY bin_id
            ORDER BY measured_at
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rate_pct_per_hour
    FROM observations
),
forecast AS (
    SELECT
        bin_code,
        measured_at,
        fill_pct,
        points_count,
        rate_pct_per_hour,
        CASE
            WHEN rate_pct_per_hour > 0
             AND points_count >= 3
            THEN (
                (100.0 - fill_pct) / rate_pct_per_hour
            )::numeric
            ELSE NULL
        END AS hours_to_full
    FROM speed
    WHERE measured_at =
          '2025-11-12 14:00:00+02'::timestamptz
)
SELECT
    bin_code,
    TO_CHAR(
        measured_at AT TIME ZONE 'Europe/Kyiv',
        'YYYY-MM-DD HH24:MI'
    ) AS local_time,
    fill_pct,
    ROUND(rate_pct_per_hour::numeric, 2)
        AS fill_rate_pct_per_hour,
    ROUND(hours_to_full, 2) AS hours_to_full,
    CASE
        WHEN hours_to_full < 4
        THEN 'URGENT'
        ELSE 'NORMAL'
    END AS priority
FROM forecast
WHERE hours_to_full >= 0
  AND hours_to_full < 4
ORDER BY hours_to_full, bin_code;
