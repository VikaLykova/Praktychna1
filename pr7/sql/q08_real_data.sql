-- q08. Реальні дані SaveEcoBot (Практична робота № 4).
-- (а) Середньорічне PM2.5 за дійсними добами і повнота даних
SET client_encoding = 'UTF8';
SET search_path TO airq, public;
SELECT c.name,
       extract(year FROM p.day)::int AS year,
       count(*)                           AS days,
       count(*) FILTER (WHERE p.is_valid) AS valid_days,
       round(avg(p.pm25_mean) FILTER (WHERE p.is_valid), 1) AS pm25_year,
       count(*) FILTER (WHERE p.is_valid AND p.pm25_mean > 15) AS days_over_who
FROM city_pm25_daily p
JOIN city c USING (city_id)
GROUP BY c.name, year
ORDER BY c.name, year;

-- (б) Три найбрудніші місяці кожного міста (віконна функція в підзапиті)
SELECT name, month, pm25_month
FROM (
  SELECT c.name,
         to_char(date_trunc('month', p.day), 'YYYY-MM') AS month,
         round(avg(p.pm25_mean), 1) AS pm25_month,
         row_number() OVER (PARTITION BY c.name
                            ORDER BY avg(p.pm25_mean) DESC) AS rn
  FROM city_pm25_daily p
  JOIN city c USING (city_id)
  WHERE p.is_valid
  GROUP BY c.name, date_trunc('month', p.day)
) AS t
WHERE rn <= 3
ORDER BY name, rn;

-- (в) Доби, коли в Харкові було брудніше, ніж у Києві, за роками (самоз'єднання)
SELECT extract(year FROM kh.day)::int AS year,
       count(*) AS days_both,
       count(*) FILTER (WHERE kh.pm25_mean > ky.pm25_mean) AS kharkiv_worse
FROM city_pm25_daily kh
JOIN city ckh ON ckh.city_id = kh.city_id AND ckh.slug = 'kharkiv'
JOIN city_pm25_daily ky ON ky.day = kh.day
JOIN city cky ON cky.city_id = ky.city_id AND cky.slug = 'kyiv'
WHERE kh.is_valid AND ky.is_valid
GROUP BY year
ORDER BY year;
