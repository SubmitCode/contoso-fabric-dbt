-- stg_product.sql
-- Silver layer: staged product dimension
-- Source: bronze_product (Lakehouse Delta table)
--
-- TODO: Implement this model using your AI coding agent.

SELECT
    -- TODO: implement column selection with correct type casting
    -- Required columns: product_key, product_name, category, subcategory
    1 AS placeholder  -- remove this line when implementing
FROM {{ source('bronze', 'bronze_product') }}
