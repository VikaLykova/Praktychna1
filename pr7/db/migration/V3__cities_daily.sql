-- V3: міста і добові дані SaveEcoBot (результат Практичної роботи № 4)
CREATE TABLE city (
  city_id      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  saveecobot_id integer NOT NULL UNIQUE,
  slug         varchar(40)  NOT NULL UNIQUE,
  name         varchar(100) NOT NULL,
  region       varchar(100) NOT NULL,
  katottg      varchar(19)  NOT NULL UNIQUE
);

INSERT INTO city (saveecobot_id, slug, name, region, katottg) VALUES
  (1,   'dnipro',  'Дніпро', 'Дніпропетровська область', 'UA12020010010037010'),
  (2,   'kyiv',    'Київ',   'Київ',                     'UA80000000000093317'),
  (219, 'kharkiv', 'Харків', 'Харківська область',       'UA63120270010096107'),
  (245, 'lviv',    'Львів',  'Львівська область',        'UA46060250010015970');

-- Зміна наявної таблиці у три кроки: додати стовпець, заповнити, заборонити NULL
ALTER TABLE district ADD COLUMN city_id integer REFERENCES city;
UPDATE district
   SET city_id = (SELECT city_id FROM city WHERE slug = 'kharkiv')
 WHERE city_id IS NULL;
ALTER TABLE district ALTER COLUMN city_id SET NOT NULL;
-- Назва району унікальна в межах міста, а не всієї бази
ALTER TABLE district DROP CONSTRAINT district_name_key;
ALTER TABLE district ADD CONSTRAINT district_city_name_key UNIQUE (city_id, name);

CREATE TABLE city_pm25_daily (
  city_id        integer NOT NULL REFERENCES city ON DELETE CASCADE,
  day            date    NOT NULL,
  pm25_mean      numeric(6,2) NOT NULL CHECK (pm25_mean >= 0),
  pm25_max       numeric(6,2) NOT NULL,
  hours_observed smallint NOT NULL CHECK (hours_observed BETWEEN 1 AND 24),
  is_valid       boolean GENERATED ALWAYS AS (hours_observed >= 18) STORED,
  PRIMARY KEY (city_id, day),
  CHECK (pm25_max >= pm25_mean)
);
