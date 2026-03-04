-- fct_sales.sql
-- Gold layer: wide fact table joining sales with all dimension tables
-- Source: silver staging models
--
-- Rules:
--   - Use LEFT JOIN for all dimension joins (prevent row loss from unmatched keys)
--   - Do not filter rows here — filtering happens in the serving layer
--
-- Required output columns:
--   order_key, line_number, order_date, delivery_date,
--   quantity, unit_price, net_price, unit_cost,
--   customer_key, continent,
--   product_key, product_name, category,
--   store_key, store_name
--
-- TODO: Implement this model using your AI coding agent.
-- Share CLAUDE.md with your agent before starting.

SELECT
    -- TODO: implement the join and column selection
    1 AS placeholder  -- remove this line when implementing
FROM {{ ref('stg_sales') }} s
-- TODO: add LEFT JOINs to stg_customer, stg_product, stg_store
