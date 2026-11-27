-- q06. Епізоди перевищення: безперервні проміжки годин із PM2.5 >= 35 мкг/м³.
-- Прийом «острови і проміжки»: у межах одного епізоду різниця між номером
-- години і порядковим номером рядка однакова, тому за нею можна групувати.
-- Скрипт можна виконувати повторно: спершу таблиця тривог очищується
SET client_encoding = 'UTF8';
SET search_path TO airq, public;
TRUNCATE alert RESTART IDENTITY;

INSERT INTO alert (station_id, threshold_id, started_at, ended_at, max_value)
WITH over AS (
  SELECT se.station_id, m.measured_at, m.value,
         m.measured_at - row_number() OVER (PARTITION BY se.station_id
                                            ORDER BY m.measured_at)
                         * interval '1 hour' AS grp
  FROM measurement m
  JOIN sensor se USING (sensor_id)
  WHERE m.pollutant_code = 'PM2.5' AND m.quality = 'O' AND m.value >= 35
)
SELECT o.station_id, t.threshold_id,
       min(o.measured_at),
       max(o.measured_at) + interval '1 hour',
       max(o.value)
FROM over o
JOIN alert_threshold t
  ON t.pollutant_code = 'PM2.5' AND t.severity = 'warning'
GROUP BY o.station_id, t.threshold_id, o.grp
HAVING count(*) >= 3;          -- епізод триває щонайменше 3 години

-- Зведення тривог за станціями
SELECT s.code, count(*) AS alerts,
       round(sum(extract(epoch FROM a.ended_at - a.started_at)) / 3600) AS hours,
       round(max(a.max_value)::numeric, 1) AS max_pm25
FROM alert a
JOIN station s USING (station_id)
GROUP BY s.code
ORDER BY hours DESC;
