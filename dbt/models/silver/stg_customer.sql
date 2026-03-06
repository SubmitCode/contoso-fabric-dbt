-- stg_customer.sql
-- Silver layer: staged customer dimension
-- Source: bronze_customer (Lakehouse Delta table via cross-database reference)
-- Transformations: rename to snake_case, cast types — no business logic
-- Note: continent is required (not_null) — used in serving layer filter

SELECT
    CAST(CustomerKey    AS BIGINT)        AS customer_key,
    CAST(GeoAreaKey     AS BIGINT)        AS geo_area_key,
    CAST(Continent      AS VARCHAR(50))   AS continent,
    CAST(Gender         AS VARCHAR(10))   AS gender,
    CAST(GivenName      AS VARCHAR(100))  AS given_name,
    CAST(Surname        AS VARCHAR(100))  AS surname,
    CAST(City           AS VARCHAR(100))  AS city,
    CAST(State          AS VARCHAR(100))  AS state,
    CAST(Country        AS VARCHAR(100))  AS country,
    CAST(CountryFull    AS VARCHAR(100))  AS country_full,
    CAST(Birthday       AS DATE)          AS birthday,
    CAST(Age            AS INT)           AS age,
    CAST(Occupation     AS VARCHAR(100))  AS occupation,
    CAST(Latitude       AS DECIMAL(10,6)) AS latitude,
    CAST(Longitude      AS DECIMAL(10,6)) AS longitude
FROM {{ source('bronze', 'bronze_customer') }}
