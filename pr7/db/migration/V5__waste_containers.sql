
-- V5: Таблиці для моніторингу контейнерів відходів

-- 1. Майданчики для збору відходів
CREATE TABLE airq.waste_site (
    site_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    district_id integer NOT NULL
        REFERENCES airq.district(district_id)
        ON DELETE RESTRICT,
    site_code varchar(20) NOT NULL UNIQUE,
    address varchar(200) NOT NULL,
    installed_on date NOT NULL,
    sorting_enabled boolean NOT NULL DEFAULT false
);

-- 2. Сміттєві контейнери
CREATE TABLE airq.bin (
    bin_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    site_id integer NOT NULL
        REFERENCES airq.waste_site(site_id)
        ON DELETE RESTRICT,
    bin_code varchar(30) NOT NULL UNIQUE,
    waste_type varchar(30) NOT NULL,
    capacity_l numeric(8,1) NOT NULL,
    height_cm numeric(6,1) NOT NULL,
    is_active boolean NOT NULL DEFAULT true,

    CONSTRAINT chk_bin_capacity
        CHECK (capacity_l > 0),

    CONSTRAINT chk_bin_height
        CHECK (height_cm > 0)
);

-- 3. Історія вимірювань заповнення
CREATE TABLE airq.fill_reading (
    reading_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    bin_id integer NOT NULL
        REFERENCES airq.bin(bin_id)
        ON DELETE RESTRICT,
    measured_at timestamptz NOT NULL,
    distance_cm numeric(6,1) NOT NULL,
    fill_pct numeric(5,2) NOT NULL,

    CONSTRAINT chk_reading_distance
        CHECK (distance_cm >= 0),

    CONSTRAINT chk_reading_fill
        CHECK (fill_pct BETWEEN 0 AND 100),

    CONSTRAINT uq_bin_measurement
        UNIQUE (bin_id, measured_at)
);
