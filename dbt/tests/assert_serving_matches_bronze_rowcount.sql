-- assert_serving_matches_bronze_rowcount.sql
-- Custom singular test: validates that the serving view row count
-- matches the number of European orders in bronze.
--
-- dbt singular test behavior: this test FAILS if the query returns any rows.
-- The query returns a row only when the counts differ — so 0 rows = test passes.
--
-- Failure usually means:
--   1. A bad JOIN in fct_sales is creating duplicate rows (use LEFT JOIN, not INNER JOIN)
--   2. The continent filter value doesn't match exactly

WITH bronze_europe_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ source('bronze', 'bronze_sales') }} s
    INNER JOIN {{ source('bronze', 'bronze_customer') }} c
        ON s.customer_key = c.customer_key
    WHERE c.continent = 'Europe'  -- ⚠️ verify this matches the actual value in your data
),

serving_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ ref('europe_fct_sales') }}
)

SELECT
    b.cnt AS bronze_europe_count,
    sv.cnt AS serving_count,
    b.cnt - sv.cnt AS difference
FROM bronze_europe_count b
CROSS JOIN serving_count sv
WHERE b.cnt != sv.cnt
