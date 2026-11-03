-- ПР5, варіант 4. Контейнери твердих побутових відходів

CREATE TABLE waste (
    ts        timestamptz NOT NULL,
    bin       text        NOT NULL,
    d         real        NOT NULL CHECK (d BETWEEN 0 AND 150),
    h         real        NOT NULL CHECK (h = 120),
    fill      real        NOT NULL CHECK (fill BETWEEN 0 AND 100),
    fill_ema  real        NOT NULL CHECK (fill_ema BETWEEN 0 AND 100),
    rate      real,
    t100      real        CHECK (t100 IS NULL OR t100 >= 0),
    alarm     smallint    NOT NULL CHECK (alarm IN (0, 1)),
    lag_ms    integer     NOT NULL,
    PRIMARY KEY (bin, ts)
);

CREATE INDEX waste_ts_idx ON waste (ts);

CREATE TABLE bin_status (
    ts      timestamptz NOT NULL DEFAULT now(),
    bin     text        NOT NULL,
    online  smallint    NOT NULL CHECK (online IN (0, 1))
);

CREATE INDEX bin_status_ts_idx ON bin_status (ts);