-- V1: початкова схема бази моніторингу якості повітря (Лекція 7)
CREATE TYPE sensor_status AS ENUM ('active', 'maintenance', 'faulty');

CREATE TABLE district (
  district_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name        varchar(100) NOT NULL UNIQUE,
  population  integer CHECK (population >= 0),
  area_km2    numeric(8,2) CHECK (area_km2 > 0)
);

CREATE TABLE station (
  station_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code         varchar(20)  NOT NULL UNIQUE,
  name         varchar(150) NOT NULL,
  district_id  integer NOT NULL REFERENCES district,
  lat          numeric(9,6) NOT NULL CHECK (lat BETWEEN -90 AND 90),
  lon          numeric(9,6) NOT NULL CHECK (lon BETWEEN -180 AND 180),
  station_type varchar(10)  NOT NULL
               CHECK (station_type IN ('reference', 'lowcost')),
  installed_on date,
  lab_name         varchar(150),  -- лише для еталонних станцій
  network_operator varchar(100),  -- лише для сенсорних станцій
  CHECK ((station_type = 'reference' AND lab_name IS NOT NULL)
      OR (station_type = 'lowcost' AND network_operator IS NOT NULL))
);

CREATE TABLE sensor (
  sensor_id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  station_id    integer NOT NULL
                REFERENCES station ON DELETE CASCADE,
  serial_no     varchar(50) NOT NULL UNIQUE,
  model         varchar(60) NOT NULL,
  calibrated_on date,
  status        sensor_status NOT NULL DEFAULT 'active'
);

CREATE TABLE pollutant (
  pollutant_code varchar(10) PRIMARY KEY,
  name           varchar(60) NOT NULL,
  unit           varchar(10) NOT NULL
);

-- Канал: який датчик яку речовину вимірює (зв'язок «багато до багатьох»)
CREATE TABLE sensor_channel (
  sensor_id      integer REFERENCES sensor ON DELETE CASCADE,
  pollutant_code varchar(10) REFERENCES pollutant,
  range_max      numeric(8,2),
  error_pct      numeric(5,2),
  PRIMARY KEY (sensor_id, pollutant_code)
);

CREATE TABLE measurement (
  measurement_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  sensor_id      integer NOT NULL,
  pollutant_code varchar(10) NOT NULL,
  measured_at    timestamptz NOT NULL,
  value          double precision NOT NULL,
  quality        char(1) NOT NULL DEFAULT 'O'
                 CHECK (quality IN ('O', 'S', 'R')),
  FOREIGN KEY (sensor_id, pollutant_code)
    REFERENCES sensor_channel ON DELETE CASCADE
);

-- Довідкові дані: перелік речовин
INSERT INTO pollutant (pollutant_code, name, unit) VALUES
  ('PM2.5', 'Тверді частинки PM2.5', 'мкг/м³'),
  ('PM10',  'Тверді частинки PM10',  'мкг/м³'),
  ('NO2',   'Діоксид азоту',         'мкг/м³');
