-- stg_store.sql
-- Silver layer: staged store dimension
-- Source: bronze_store (Lakehouse Delta table)
--
-- TODO: Implement this model using your AI coding agent.

SELECT
    -- TODO: implement column selection with correct type casting
    -- Required columns: store_key, store_name, country
    1 AS placeholder  -- remove this line when implementing
FROM {{ source('bronze', 'bronze_store') }}
