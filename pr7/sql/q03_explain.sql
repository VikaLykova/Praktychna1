-- q03. План виконання запиту: тиждень вимірів одного датчика.
-- Виконайте ДО і ПІСЛЯ міграції V4 і порівняйте план та час.
SET client_encoding = 'UTF8';
SET search_path TO airq, public;
EXPLAIN (ANALYZE, BUFFERS)
SELECT avg(value)
FROM measurement
WHERE sensor_id = 3 AND pollutant_code = 'PM2.5'
  AND measured_at >= '2025-11-01' AND measured_at < '2025-11-08';
