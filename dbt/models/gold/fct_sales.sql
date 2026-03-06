-- fct_sales.sql
-- Gold layer: wide fact table joining sales with all dimension tables
-- Uses LEFT JOIN for all dimension joins to prevent row loss from unmatched keys

SELECT
    s.order_key,
    s.line_number,
    s.order_date,
    s.delivery_date,
    s.quantity,
    s.unit_price,
    s.net_price,
    s.unit_cost,
    s.currency_code,
    s.exchange_rate,
    c.customer_key,
    c.continent,
    c.country                   AS customer_country,
    p.product_key,
    p.product_name,
    p.category,
    p.subcategory,
    p.brand,
    st.store_key,
    st.store_name,
    st.country_code             AS store_country_code
FROM {{ ref('stg_sales') }} s
LEFT JOIN {{ ref('stg_customer') }} c
    ON s.customer_key = c.customer_key
LEFT JOIN {{ ref('stg_product') }} p
    ON s.product_key = p.product_key
LEFT JOIN {{ ref('stg_store') }} st
    ON s.store_key = st.store_key
