-- q05. Віконні функції.
-- (а) Ковзне середнє за 24 години для станції ST03
SET client_encoding = 'UTF8';
SET search_path TO airq, public;
SELECT m.measured_at AT TIME ZONE 'Europe/Kyiv' AS local_time,
       m.value AS pm25,
       round(avg(m.value) OVER (ORDER BY m.measured_at
             ROWS BETWEEN 23 PRECEDING AND CURRENT ROW)::numeric, 1) AS pm25_24h
FROM measurement m
JOIN sensor  se USING (sensor_id)
JOIN station s  USING (station_id)
WHERE s.code = 'ST03' AND m.pollutant_code = 'PM2.5' AND m.quality = 'O'
  AND m.measured_at >= '2025-11-13' AND m.measured_at < '2025-11-15'
ORDER BY m.measured_at
LIMIT 6 OFFSET 24;

-- (б) Місце станції серед інших за середньомісячним PM2.5 (RANK)
--     і зміна проти попереднього місяця (LAG)
WITH monthly AS (
  SELECT s.code,
         date_trunc('month', m.measured_at AT TIME ZONE 'Europe/Kyiv')::date AS month,
         avg(m.value) AS pm25
  FROM measurement m
  JOIN sensor  se USING (sensor_id)
  JOIN station s  USING (station_id)
  WHERE m.pollutant_code = 'PM2.5' AND m.quality = 'O'
  GROUP BY s.code, month
)
SELECT code, month,
       round(pm25::numeric, 1) AS pm25,
       rank() OVER (PARTITION BY month ORDER BY pm25 DESC) AS place,
       round((pm25 - lag(pm25) OVER (PARTITION BY code ORDER BY month))::numeric, 1)
         AS change
FROM monthly
WHERE month >= '2025-10-01'
ORDER BY month, place;
