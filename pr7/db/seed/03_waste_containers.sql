
-- ПР7. Варіант 4. Контейнери відходів
-- Відтворювана генерація тестових даних

SELECT setseed(0.7);

SET client_encoding = 'UTF8';
SET search_path TO airq, public;

-- 1. Майданчики для збору відходів
INSERT INTO airq.waste_site
    (district_id, site_code, address, installed_on, sorting_enabled)
SELECT
    d.district_id,
    v.site_code,
    v.address,
    v.installed_on::date,
    v.sorting_enabled
FROM (VALUES
    ('WS-01', 'Київський', 'вул. Сумська, 15', '2025-01-15', true),
    ('WS-02', 'Київський', 'вул. Мироносицька, 42', '2025-02-10', true),
    ('WS-03', 'Холодногірський', 'вул. Полтавський Шлях, 88', '2025-03-01', false),
    ('WS-04', 'Холодногірський', 'вул. Велика Панасівська, 30', '2025-03-20', true),
    ('WS-05', 'Індустріальний', 'просп. Індустріальний, 25', '2025-04-05', false),
    ('WS-06', 'Індустріальний', 'вул. Біблика, 12', '2025-04-18', true)
) AS v(site_code, district_name, address, installed_on, sorting_enabled)
JOIN airq.district d ON d.name = v.district_name;

-- 2. Контейнери
INSERT INTO airq.bin
    (site_id, bin_code, waste_type, capacity_l, height_cm, is_active)
SELECT
    s.site_id,
    v.bin_code,
    v.waste_type,
    v.capacity_l,
    v.height_cm,
    true
FROM (VALUES
    ('BIN-01', 'WS-01', 'mixed', 1100, 140),
    ('BIN-02', 'WS-01', 'plastic', 1100, 140),
    ('BIN-03', 'WS-02', 'mixed', 1100, 140),
    ('BIN-04', 'WS-02', 'paper', 770, 120),
    ('BIN-05', 'WS-03', 'glass', 660, 110),
    ('BIN-06', 'WS-03', 'mixed', 1100, 140),
    ('BIN-07', 'WS-04', 'plastic', 770, 120),
    ('BIN-08', 'WS-04', 'paper', 770, 120),
    ('BIN-09', 'WS-05', 'mixed', 1100, 140),
    ('BIN-10', 'WS-05', 'organic', 660, 110),
    ('BIN-11', 'WS-06', 'glass', 660, 110),
    ('BIN-12', 'WS-06', 'mixed', 1100, 140)
) AS v(bin_code, site_code, waste_type, capacity_l, height_cm)
JOIN airq.waste_site s ON s.site_code = v.site_code;

-- 3. Погодинні вимірювання за листопад 2025 року
-- 12 контейнерів × 30 діб × 24 години = 8640 записів
-- Уночі моделюється спорожнення контейнерів
-- Для BIN-03 моделюється епізод переповнення 12 листопада

WITH generated AS MATERIALIZED (
    SELECT
        b.bin_id,
        b.bin_code,
        b.height_cm,
        t.measured_at,
        CASE
            WHEN b.bin_code = 'BIN-03'
                 AND t.measured_at >= '2025-11-12 14:00:00+02'::timestamptz
                 AND t.measured_at < '2025-11-13 00:00:00+02'::timestamptz
            THEN 96 + random() * 3
            ELSE LEAST(
                99.0,
                15.0
                + EXTRACT(HOUR FROM t.measured_at) * 3.1
                + (b.bin_id % 3) * 2
                + random() * 3
            )
        END AS fill_value
    FROM airq.bin b
    CROSS JOIN generate_series(
        '2025-11-01 00:00:00+02'::timestamptz,
        '2025-11-30 23:00:00+02'::timestamptz,
        INTERVAL '1 hour'
    ) AS t(measured_at)
)
INSERT INTO airq.fill_reading
    (bin_id, measured_at, distance_cm, fill_pct)
SELECT
    bin_id,
    measured_at,
    ROUND((height_cm * (100 - fill_value) / 100)::numeric, 1),
    ROUND(fill_value::numeric, 2)
FROM generated;

-- 4. Оновлення статистики PostgreSQL
ANALYZE airq.waste_site;
ANALYZE airq.bin;
ANALYZE airq.fill_reading;

-- 5. Перевірка кількості записів
SELECT 'waste_site' AS table_name, COUNT(*) AS rows_count
FROM airq.waste_site
UNION ALL
SELECT 'bin', COUNT(*)
FROM airq.bin
UNION ALL
SELECT 'fill_reading', COUNT(*)
FROM airq.fill_reading
ORDER BY table_name;

-- 6. Перевірка випадку переповнення
SELECT
    b.bin_code,
    COUNT(*) AS critical_readings,
    MAX(f.fill_pct) AS max_fill_pct
FROM airq.fill_reading f
JOIN airq.bin b ON b.bin_id = f.bin_id
WHERE f.fill_pct >= 95
GROUP BY b.bin_code
ORDER BY critical_readings DESC;
