-- stg_sales.sql
-- Silver layer: staged sales table
-- Source: bronze_sales (Lakehouse Delta table via cross-database reference)
-- Transformations: rename to snake_case, cast types — no business logic

SELECT
    CAST(OrderKey       AS BIGINT)  AS order_key,
    CAST(LineNumber     AS INT)     AS line_number,
    CAST(OrderDate      AS DATE)    AS order_date,
    CAST(DeliveryDate   AS DATE)    AS delivery_date,
    CAST(CustomerKey    AS BIGINT)  AS customer_key,
    CAST(StoreKey       AS BIGINT)  AS store_key,
    CAST(ProductKey     AS BIGINT)  AS product_key,
    CAST(Quantity       AS INT)     AS quantity,
    CAST(UnitPrice      AS DECIMAL(18,4)) AS unit_price,
    CAST(NetPrice       AS DECIMAL(18,4)) AS net_price,
    CAST(UnitCost       AS DECIMAL(18,4)) AS unit_cost,
    CAST(CurrencyCode   AS VARCHAR(10))   AS currency_code,
    CAST(ExchangeRate   AS DECIMAL(18,6)) AS exchange_rate
FROM {{ source('bronze', 'bronze_sales') }}
