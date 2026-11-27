-- q03b. Розмір таблиці та її індексів
SET client_encoding = 'UTF8';
SET search_path TO airq, public;
SELECT c.relname AS object,
       CASE c.relkind WHEN 'r' THEN 'таблиця' ELSE 'індекс' END AS kind,
       pg_size_pretty(pg_relation_size(c.oid)) AS size
FROM pg_class c
WHERE c.oid = 'measurement'::regclass
   OR c.oid IN (SELECT indexrelid FROM pg_index
                WHERE indrelid = 'measurement'::regclass)
ORDER BY pg_relation_size(c.oid) DESC;
