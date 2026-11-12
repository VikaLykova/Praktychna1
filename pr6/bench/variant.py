"""Варіант 4. DuckDB замість pandas."""

import duckdb
import pandas as pd

from bench.common import (
    COLUMNS,
    EU_DAILY_2030,
    MIN_HOURS,
    WHO_DAILY,
    YEARS,
    raw_file,
)


def compute_indicators() -> pd.DataFrame:
    files = ", ".join(
        f"'{raw_file(year).as_posix()}'"
        for year in YEARS
    )

    query = f"""
    WITH src AS (
        SELECT DISTINCT
            CAST(city_id AS INTEGER) AS city_id,
            CAST(pm25 AS DOUBLE) AS pm25,
            CAST(logged_at AS TIMESTAMP) AS logged_at
        FROM read_csv_auto(
            [{files}],
            nullstr='NULL'
        )
        WHERE city_id IN (2, 219)
          AND pm25 BETWEEN 0 AND 1000
    ),

    daily AS (
        SELECT
            city_id,
            CAST(date_trunc('day', logged_at) AS DATE) AS day,
            AVG(pm25) AS daily_mean,
            COUNT(*) AS measurements
        FROM src
        GROUP BY city_id, day
        HAVING COUNT(*) >= {MIN_HOURS}
    ),

    annual AS (
        SELECT
            city_id,
            CAST(EXTRACT(year FROM day) AS INTEGER) AS year,
            AVG(daily_mean) AS annual_mean,
            CAST(COUNT(*) AS INTEGER) AS valid_days,
            CAST(SUM(
                CASE WHEN daily_mean > {WHO_DAILY}
                THEN 1 ELSE 0 END
            ) AS INTEGER) AS days_over_15,
            CAST(SUM(
                CASE WHEN daily_mean > {EU_DAILY_2030}
                THEN 1 ELSE 0 END
            ) AS INTEGER) AS days_over_25
        FROM daily
        GROUP BY city_id, year
    )

    SELECT
        city_id,
        year,
        annual_mean,
        valid_days,
        CASE
            WHEN year % 400 = 0
              OR (year % 4 = 0 AND year % 100 <> 0)
            THEN 366
            ELSE 365
        END AS days_in_year,
        days_over_15,
        days_over_25,
        valid_days * 100.0 /
        CASE
            WHEN year % 400 = 0
              OR (year % 4 = 0 AND year % 100 <> 0)
            THEN 366
            ELSE 365
        END AS completeness_pct,
        CASE
            WHEN annual_mean <= 5 THEN 'настанова ВООЗ'
            WHEN annual_mean <= 10 THEN 'IT-4'
            WHEN annual_mean <= 15 THEN 'IT-3'
            WHEN annual_mean <= 25 THEN 'IT-2'
            WHEN annual_mean <= 35 THEN 'IT-1'
            ELSE 'гірше IT-1'
        END AS who_level
    FROM annual
    ORDER BY city_id, year
    """

    result = duckdb.sql(query).df()

    result = result.set_index(["city_id", "year"])
    return result[COLUMNS]