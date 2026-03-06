-- stg_sales.sql
-- Silver layer: staged sales table
-- Source: bronze_sales (Lakehouse Delta table)
-- Transformations: type casting only — no business logic
--
-- TODO: Implement this model using your AI coding agent.
-- Refer to AGENTS.md for cross-database source configuration.
-- Refer to HINTS.md Hint 2 for how to reference the Lakehouse source.
-- Note: bronze columns are CamelCase (OrderKey, OrderDate, UnitPrice, etc.)

SELECT
    -- TODO: implement column selection with correct type casting
    -- Required columns: order_key, line_number, order_date (DATE), delivery_date (DATE),
    --   customer_key, store_key, product_key, quantity, unit_price, net_price, unit_cost
    1 AS placeholder  -- remove this line when implementing
FROM {{ source('bronze', 'bronze_sales') }}
