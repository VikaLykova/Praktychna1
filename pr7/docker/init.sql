-- Виконується один раз під час першого запуску контейнера postgres (порожній том pgdata)
ALTER DATABASE cityair SET search_path TO airq, public;
