-- europe_fct_sales.sql
-- Serving layer: European sales view
-- Filters fct_sales to customers with continent = 'Europe'
--
-- Naming convention: {continent_lowercase}_{gold_model}
--
-- ⚠️  Verify the exact continent value before implementing:
--     SELECT DISTINCT continent FROM silver.stg_customer
--
-- TODO: Implement this model using your AI coding agent.

SELECT
    -- TODO: implement the filter
    1 AS placeholder  -- remove this line when implementing
FROM {{ ref('fct_sales') }}
-- WHERE continent = 'Europe'  -- uncomment and verify the exact value
