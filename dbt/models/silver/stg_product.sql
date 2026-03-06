-- stg_product.sql
-- Silver layer: staged product dimension
-- Source: bronze_product (Lakehouse Delta table via cross-database reference)
-- Transformations: rename to snake_case, cast types — no business logic

SELECT
    CAST(ProductKey      AS BIGINT)        AS product_key,
    CAST(ProductCode     AS VARCHAR(50))   AS product_code,
    CAST(ProductName     AS VARCHAR(200))  AS product_name,
    CAST(Manufacturer    AS VARCHAR(100))  AS manufacturer,
    CAST(Brand           AS VARCHAR(100))  AS brand,
    CAST(Color           AS VARCHAR(50))   AS color,
    CAST(Cost            AS DECIMAL(18,4)) AS cost,
    CAST(Price           AS DECIMAL(18,4)) AS price,
    CAST(CategoryKey     AS BIGINT)        AS category_key,
    CAST(CategoryName    AS VARCHAR(100))  AS category,
    CAST(SubCategoryKey  AS BIGINT)        AS subcategory_key,
    CAST(SubCategoryName AS VARCHAR(100))  AS subcategory
FROM {{ source('bronze', 'bronze_product') }}
