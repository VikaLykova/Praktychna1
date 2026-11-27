-- Застосування міграцій: виконує лише ті версії, яких ще немає в schema_history.
-- Запуск у pgAdmin: Tools -> PSQL Tool, далі команда (шлях - до вашої папки pr7):
--   \i 'C:/Users/student/iit/pr7/db/migrate.sql'
-- Запуск у терміналі (з папки pr7/db):  psql -U postgres -d cityair -f migrate.sql
\encoding UTF8
\set ON_ERROR_STOP on
SET client_min_messages TO warning;
CREATE SCHEMA IF NOT EXISTS airq;
SET search_path TO airq, public;

CREATE TABLE IF NOT EXISTS schema_history (
  version      integer PRIMARY KEY,
  script       text NOT NULL,
  installed_on timestamptz NOT NULL DEFAULT now(),
  installed_by text NOT NULL DEFAULT current_user
);

-- ---------- V1 ----------
SELECT NOT EXISTS (SELECT 1 FROM schema_history WHERE version = 1) AS todo \gset
\if :todo
  \echo 'V1__init.sql: applying'
  BEGIN;
  \ir migration/V1__init.sql
  INSERT INTO schema_history (version, script) VALUES (1, 'V1__init.sql');
  COMMIT;
\endif

-- ---------- V2 ----------
SELECT NOT EXISTS (SELECT 1 FROM schema_history WHERE version = 2) AS todo \gset
\if :todo
  \echo 'V2__alerts.sql: applying'
  BEGIN;
  \ir migration/V2__alerts.sql
  INSERT INTO schema_history (version, script) VALUES (2, 'V2__alerts.sql');
  COMMIT;
\endif

-- ---------- V3 ----------
SELECT NOT EXISTS (SELECT 1 FROM schema_history WHERE version = 3) AS todo \gset
\if :todo
  \echo 'V3__cities_daily.sql: applying'
  BEGIN;
  \ir migration/V3__cities_daily.sql
  INSERT INTO schema_history (version, script) VALUES (3, 'V3__cities_daily.sql');
  COMMIT;
\endif

-- ---------- V4: індекси ----------
SELECT NOT EXISTS (SELECT 1 FROM schema_history WHERE version = 4) AS todo \gset
\if :todo
  \echo 'V4__measurement_indexes.sql: applying'
  BEGIN;
  \ir migration/V4__measurement_indexes.sql
  INSERT INTO schema_history (version, script) VALUES (4, 'V4__measurement_indexes.sql');
  COMMIT;
\endif

-- ---------- нові міграції (V5, V6 ...) додавайте нижче за тим самим зразком ----------

-- ---------- V5: контейнери відходів ----------
SELECT NOT EXISTS (
    SELECT 1 FROM schema_history WHERE version = 5
) AS todo \gset

\if :todo
  \echo 'V5__waste_containers.sql: applying'
  BEGIN;
  \ir migration/V5__waste_containers.sql
  INSERT INTO schema_history (version, script)
  VALUES (5, 'V5__waste_containers.sql');
  COMMIT;
\endif

-- ---------- V6: індекс критичного заповнення ----------
SELECT NOT EXISTS (
    SELECT 1 FROM schema_history WHERE version = 6
) AS todo \gset

\if :todo
  \echo 'V6__critical_fill_index.sql: applying'
  BEGIN;
  \ir migration/V6__critical_fill_index.sql
  INSERT INTO schema_history (version, script)
  VALUES (6, 'V6__critical_fill_index.sql');
  COMMIT;
\endif

-- ---------- V7: періодичність вивезення ----------
SELECT NOT EXISTS (
    SELECT 1 FROM schema_history WHERE version = 7
) AS todo \gset

\if :todo
  \echo 'V7__collection_interval.sql: applying'
  BEGIN;
  \ir migration/V7__collection_interval.sql
  INSERT INTO schema_history (version, script)
  VALUES (7, 'V7__collection_interval.sql');
  COMMIT;
\endif

\echo 'Schema history:'
SELECT version, script, to_char(installed_on, 'YYYY-MM-DD HH24:MI') AS installed
FROM schema_history ORDER BY version;
