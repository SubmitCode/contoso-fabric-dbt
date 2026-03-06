-- europe_fct_sales.sql
-- Serving layer: European sales view
-- Filters fct_sales to customers with continent = 'Europe'
-- Naming convention: {continent_lowercase}_{gold_model}

SELECT *
FROM {{ ref('fct_sales') }}
WHERE continent = 'Europe'
