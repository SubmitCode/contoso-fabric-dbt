-- stg_store.sql
-- Silver layer: staged store dimension
-- Source: bronze_store (Lakehouse Delta table via cross-database reference)
-- Transformations: rename to snake_case, cast types — no business logic

SELECT
    CAST(StoreKey     AS BIGINT)        AS store_key,
    CAST(StoreCode    AS VARCHAR(50))   AS store_code,
    CAST(GeoAreaKey   AS BIGINT)        AS geo_area_key,
    CAST(CountryCode  AS VARCHAR(10))   AS country_code,
    CAST(CountryName  AS VARCHAR(100))  AS store_name,
    CAST(State        AS VARCHAR(100))  AS state,
    CAST(OpenDate     AS DATE)          AS open_date,
    CAST(CloseDate    AS DATE)          AS close_date,
    CAST(Description  AS VARCHAR(200))  AS description,
    CAST(SquareMeters AS DECIMAL(10,2)) AS square_meters,
    CAST(Status       AS VARCHAR(20))   AS status
FROM {{ source('bronze', 'bronze_store') }}
