-- stg_customer.sql
-- Silver layer: staged customer dimension
-- Source: bronze_customer (Lakehouse Delta table)
-- Important: preserve the `continent` column — it is used in the serving layer filter.
--
-- TODO: Implement this model using your AI coding agent.

SELECT
    -- TODO: implement column selection with correct type casting
    -- Required columns: customer_key, continent (must be not_null), geo_area_key
    1 AS placeholder  -- remove this line when implementing
FROM {{ source('bronze', 'bronze_customer') }}
