-- q07. Матеріалізоване подання: добові середні за районами
SET client_encoding = 'UTF8';
SET search_path TO airq, public;
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_daily_district AS
SELECT d.district_id, d.name, d.population,
       m.pollutant_code,
       (m.measured_at AT TIME ZONE 'Europe/Kyiv')::date AS day,
       avg(m.value) AS avg_value,
       count(*)     AS n
FROM measurement m
JOIN sensor   se USING (sensor_id)
JOIN station  s  USING (station_id)
JOIN district d  USING (district_id)
WHERE m.quality = 'O'
GROUP BY d.district_id, d.name, d.population, m.pollutant_code, day;

-- Унікальний індекс потрібен для оновлення без блокування читачів
CREATE UNIQUE INDEX IF NOT EXISTS mv_daily_district_key
  ON mv_daily_district (district_id, pollutant_code, day);

-- Після надходження нових вимірів подання оновлюють явно
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_district;

-- Індикатор ЦСР 11.6.2: середньорічне значення, зважене за населенням районів
SELECT pollutant_code,
       round((sum(avg_value * population) / sum(population))::numeric, 1)
         AS weighted_mean,
       round(avg(avg_value)::numeric, 1) AS simple_mean
FROM (SELECT district_id, population, pollutant_code,
             avg(avg_value) AS avg_value
      FROM mv_daily_district
      WHERE day BETWEEN '2025-01-01' AND '2025-12-31'
      GROUP BY district_id, population, pollutant_code) AS y
GROUP BY pollutant_code
ORDER BY pollutant_code;
