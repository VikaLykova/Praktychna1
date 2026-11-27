
SET client_encoding = 'UTF8';
SET search_path TO airq, public;

-- ПР7. Варіант 4. Контейнери відходів
-- Аналіз заповненості контейнерів за районами міста

WITH container_data AS (
    SELECT
        d.district_id,
        d.name AS district,
        b.bin_id,
        b.bin_code,
        f.measured_at,
        ROUND(
            (100 * (1 - f.distance_cm / NULLIF(b.height_cm, 0)))::numeric,
            2
        ) AS fill_pct
    FROM district d
    JOIN waste_site ws
        ON ws.district_id = d.district_id
    JOIN bin b
        ON b.site_id = ws.site_id
    JOIN fill_reading f
        ON f.bin_id = b.bin_id
    WHERE f.measured_at >= '2025-11-01 00:00:00+02'
      AND f.measured_at < '2025-12-01 00:00:00+02'
      AND b.is_active = true
)
SELECT
    district AS district_name,
    COUNT(DISTINCT bin_id) AS total_bins,
    COUNT(*) AS total_readings,
    ROUND(AVG(fill_pct), 2) AS avg_fill_pct,
    ROUND(MAX(fill_pct), 2) AS max_fill_pct,
    COUNT(*) FILTER (
        WHERE fill_pct >= 80
    ) AS critical_readings,
    COUNT(DISTINCT bin_id) FILTER (
        WHERE fill_pct >= 80
    ) AS critical_bins
FROM container_data
GROUP BY district_id, district
HAVING COUNT(*) FILTER (
    WHERE fill_pct >= 80
) > 0
ORDER BY critical_readings DESC, district_name;
