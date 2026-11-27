-- Повне очищення навчальної бази: видаляє схему airq з усіма таблицями, даними
-- та історією міграцій. Після цього migrate.sql створить усе з нуля.
SET client_min_messages TO warning;
DROP SCHEMA IF EXISTS airq CASCADE;
