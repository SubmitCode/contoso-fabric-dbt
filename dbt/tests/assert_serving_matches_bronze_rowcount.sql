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
--   3. Bronze column names are CamelCase — use CustomerKey, Continent (not customer_key, continent)
--
-- TODO: Implement this test using your AI coding agent.
--
-- The test should:
--   1. Count rows in {{ source('bronze', 'bronze_sales') }} joined to {{ source('bronze', 'bronze_customer') }}
--      filtered to European customers
--   2. Count rows in {{ ref('europe_fct_sales') }}
--   3. Return a row (fail) when the two counts differ, return nothing (pass) when they match
--
-- Hint: join bronze tables on their CamelCase key columns (CustomerKey, not customer_key)

SELECT
    1 AS placeholder  -- replace this with your implementation
WHERE 1 = 0          -- this stub always passes — replace with real logic
