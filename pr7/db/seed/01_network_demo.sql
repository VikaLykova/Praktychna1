-- Навчальні дані: 4 райони Харкова, 6 станцій, рік погодинних вимірів PM2.5 і PM10
-- (дані згенеровано; setseed робить результат однаковим на всіх комп'ютерах)
SET client_encoding = 'UTF8';
SET search_path TO airq, public;
SELECT setseed(0.42);

INSERT INTO district (name, population, area_km2, city_id)
SELECT v.name, v.population, v.area_km2, c.city_id
FROM (VALUES ('Шевченківський', 220000, 39.6),
             ('Київський',      180000, 31.2),
             ('Холодногірський', 90000, 12.1),
             ('Індустріальний', 150000, 53.0)) AS v(name, population, area_km2)
CROSS JOIN city c
WHERE c.slug = 'kharkiv';

INSERT INTO station (code, name, district_id, lat, lon, station_type,
                     installed_on, lab_name, network_operator)
SELECT v.code, v.name, d.district_id, v.lat, v.lon, v.station_type,
       v.installed_on::date, v.lab_name, v.network_operator
FROM (VALUES
  ('ST01', 'Пост ЦГО, просп. Науки',      'Шевченківський',  50.0271, 36.2208, 'reference', '2019-03-01', 'Лабораторія ЦГО', NULL),
  ('ST02', 'Олексіївка, школа № 17',      'Шевченківський',  50.0495, 36.2052, 'lowcost',   '2021-09-15', NULL, 'SaveEcoBot'),
  ('ST03', 'Салтівка, вул. Академіка Павлова', 'Київський',  50.0102, 36.3301, 'lowcost',   '2021-10-02', NULL, 'SaveEcoBot'),
  ('ST04', 'Холодна гора, вул. Полтавський Шлях', 'Холодногірський', 49.9853, 36.1862, 'lowcost', '2022-04-20', NULL, 'EcoCity'),
  ('ST05', 'ХТЗ, просп. Індустріальний',  'Індустріальний',  49.9456, 36.3987, 'lowcost',   '2022-05-11', NULL, 'EcoCity'),
  ('ST06', 'Рогань, промзона',            'Індустріальний',  49.9312, 36.4403, 'lowcost',   '2023-02-07', NULL, 'SaveEcoBot')
) AS v(code, name, district, lat, lon, station_type, installed_on, lab_name, network_operator)
JOIN district d ON d.name = v.district;

INSERT INTO sensor (station_id, serial_no, model, calibrated_on, status)
SELECT station_id, 'SN-' || code,
       CASE station_type WHEN 'reference' THEN 'Grimm EDM180' ELSE 'SDS011' END,
       date '2024-11-01' + station_id * 9,
       CASE code WHEN 'ST06' THEN 'maintenance' ELSE 'active' END::sensor_status
FROM station;

INSERT INTO sensor_channel (sensor_id, pollutant_code, range_max, error_pct)
SELECT s.sensor_id, p.code, 999.9,
       CASE s.model WHEN 'SDS011' THEN 15 ELSE 2 END
FROM sensor s CROSS JOIN (VALUES ('PM2.5'), ('PM10')) AS p(code);

-- Виміри: сезонний і добовий хід, зсув станції, шум, зимові епізоди смогу.
-- Станція ST04 стоїть біля дороги (+8); близько 1 % вимірів позначено як сумнівні.
INSERT INTO measurement (sensor_id, pollutant_code, measured_at, value, quality)
SELECT c.sensor_id, c.pollutant_code, t,
       round(greatest(1,
         (CASE c.pollutant_code WHEN 'PM2.5' THEN 10 ELSE 18 END)
           * (1 + 0.4 * cos(2 * pi() * (extract(doy FROM t) - 15) / 365.0))
           * (1 + 0.3 * cos(2 * pi() * (extract(hour FROM t) - 20) / 24.0))
         + c.sensor_id * 0.8 + random() * 5
         + CASE WHEN c.sensor_id = 4 THEN 8 ELSE 0 END
         + CASE WHEN extract(doy FROM t) IN (12, 13, 14, 40, 41, 318, 319, 350)
                THEN 30 ELSE 0 END)::numeric, 1),
       CASE WHEN random() < 0.01 THEN 'S' ELSE 'O' END
FROM sensor_channel c
CROSS JOIN generate_series('2025-01-01 00:00+02'::timestamptz,
                           '2025-12-31 23:00+02', interval '1 hour') AS t;

ANALYZE;
