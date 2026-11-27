
SET client_encoding = 'UTF8';
SET search_path TO airq, public;

-- ПР7. Варіант 4. Інтеграція даних контейнерів
-- із показниками забруднення повітря за районами міста.

WITH waste_daily AS (
    SELECT
        ws.district_id,
        COUNT(DISTINCT b.bin_id) AS total_bins,
        COUNT(*) AS total_readings,
        ROUND(AVG(
            100.0 * (1 - f.distance_cm / NULLIF(b.height_cm, 0))
        )::numeric, 2) AS avg_fill_pct,
        COUNT(*) FILTER (
            WHERE 100.0 * (1 - f.distance_cm / NULLIF(b.height_cm, 0)) >= 80
        ) AS readings_over_80,
        COUNT(*) FILTER (
            WHERE 100.0 * (1 - f.distance_cm / NULLIF(b.height_cm, 0)) >= 95
        ) AS readings_over_95
    FROM waste_site ws
    JOIN bin b ON b.site_id = ws.site_id
    JOIN fill_reading f ON f.bin_id = b.bin_id
    WHERE (f.measured_at AT TIME ZONE 'Europe/Kyiv')::date
          = DATE '2025-11-12'
    GROUP BY ws.district_id
),
air_daily AS (
    SELECT
        district_id,
        ROUND(avg_value::numeric, 2) AS pm25_avg
    FROM mv_daily_district
    WHERE pollutant_code = 'PM2.5'
      AND day = DATE '2025-11-12'
)
SELECT
    d.name AS district_name,
    d.population,
    w.total_bins,
    w.total_readings,
    w.avg_fill_pct,
    w.readings_over_80,
    w.readings_over_95,
    a.pm25_avg
FROM waste_daily w
JOIN district d ON d.district_id = w.district_id
LEFT JOIN air_daily a ON a.district_id = w.district_id
ORDER BY w.avg_fill_pct DESC;
