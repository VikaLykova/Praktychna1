-- q01. Перевірка: скільки рядків у кожній таблиці
SET client_encoding = 'UTF8';
SET search_path TO airq, public;
SELECT 'city' AS tbl, count(*) FROM city
UNION ALL SELECT 'district', count(*) FROM district
UNION ALL SELECT 'station', count(*) FROM station
UNION ALL SELECT 'sensor', count(*) FROM sensor
UNION ALL SELECT 'pollutant', count(*) FROM pollutant
UNION ALL SELECT 'sensor_channel', count(*) FROM sensor_channel
UNION ALL SELECT 'measurement', count(*) FROM measurement
UNION ALL SELECT 'alert_threshold', count(*) FROM alert_threshold
UNION ALL SELECT 'alert', count(*) FROM alert
UNION ALL SELECT 'city_pm25_daily', count(*) FROM city_pm25_daily
ORDER BY 1;
