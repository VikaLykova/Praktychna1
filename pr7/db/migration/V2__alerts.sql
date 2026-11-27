-- V2: пороги і тривоги (гістерезис, як у Практичній роботі № 5)
CREATE TABLE alert_threshold (
  threshold_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  pollutant_code varchar(10) NOT NULL REFERENCES pollutant,
  on_level       numeric(8,2) NOT NULL,
  off_level      numeric(8,2) NOT NULL,
  severity       varchar(12) NOT NULL
                 CHECK (severity IN ('warning', 'danger')),
  CHECK (off_level < on_level),
  UNIQUE (pollutant_code, severity)
);

CREATE TABLE alert (
  alert_id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  station_id   integer NOT NULL REFERENCES station ON DELETE CASCADE,
  threshold_id integer NOT NULL REFERENCES alert_threshold,
  started_at   timestamptz NOT NULL,
  ended_at     timestamptz CHECK (ended_at > started_at),
  max_value    double precision
);

INSERT INTO alert_threshold (pollutant_code, on_level, off_level, severity)
VALUES ('PM2.5', 35, 25, 'warning'), ('PM2.5', 75, 50, 'danger'),
       ('PM10',  50, 40, 'warning');
