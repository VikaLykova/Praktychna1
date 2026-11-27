-- q04. Агрегування за часом: середньомісячні значення PM2.5 станції ST04
SET client_encoding = 'UTF8';
SET search_path TO airq, public;
SELECT date_trunc('month', m.measured_at AT TIME ZONE 'Europe/Kyiv')::date AS month,
       round(avg(m.value)::numeric, 1) AS pm25_avg,
       count(*)                        AS n
FROM measurement m
JOIN sensor  se USING (sensor_id)
JOIN station s  USING (station_id)
WHERE s.code = 'ST04' AND m.pollutant_code = 'PM2.5' AND m.quality = 'O'
GROUP BY month
ORDER BY month;

-- Кількість діб 2025 р. із середньодобовим PM2.5 понад 15 мкг/м³ (настанова ВООЗ)
WITH daily AS (
  SELECT s.code,
         (m.measured_at AT TIME ZONE 'Europe/Kyiv')::date AS day,
         avg(m.value) AS pm25_day,
         count(*)     AS hours
  FROM measurement m
  JOIN sensor  se USING (sensor_id)
  JOIN station s  USING (station_id)
  WHERE m.pollutant_code = 'PM2.5' AND m.quality = 'O'
  GROUP BY s.code, day
)
SELECT code,
       count(*) FILTER (WHERE hours >= 18)                   AS valid_days,
       count(*) FILTER (WHERE hours >= 18 AND pm25_day > 15) AS days_over_who,
       round(100.0 * count(*) FILTER (WHERE hours >= 18 AND pm25_day > 15)
             / count(*) FILTER (WHERE hours >= 18), 1)       AS pct
FROM daily
GROUP BY code
ORDER BY code;
