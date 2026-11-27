-- q02. З'єднання чотирьох таблиць, групування і відбір груп.
-- Середня концентрація PM2.5 за районами у листопаді 2025 р.;
-- показуємо лише райони із середнім понад 18 мкг/м³ (HAVING відкидає групи).
SET client_encoding = 'UTF8';
SET search_path TO airq, public;
SELECT d.name                          AS district,
       count(DISTINCT s.station_id)    AS stations,
       count(*)                        AS n,
       round(avg(m.value)::numeric, 1) AS pm25_avg,
       round(max(m.value)::numeric, 1) AS pm25_max
FROM measurement m
JOIN sensor   se USING (sensor_id)
JOIN station  s  USING (station_id)
JOIN district d  USING (district_id)
WHERE m.pollutant_code = 'PM2.5'
  AND m.quality = 'O'
  AND m.measured_at >= '2025-11-01' AND m.measured_at < '2025-12-01'
GROUP BY d.name
HAVING avg(m.value) > 18
ORDER BY pm25_avg DESC;

-- LEFT JOIN: міста довідника, для яких у базі немає добових даних
SELECT c.name, count(p.day) AS days
FROM city c
LEFT JOIN city_pm25_daily p USING (city_id)
GROUP BY c.name
ORDER BY days DESC, c.name;
