# CLAUDE.md — AI Agent Context

> **Read this first.** Share this file with your AI coding agent before asking it to implement anything in this project. It contains everything needed to work on this codebase without asking follow-up questions.

---

## Project Purpose

A public, reproducible Microsoft Fabric + dbt reference implementation using Contoso V2 open data. Packaged as a no-code challenge: participants build the data pipeline using only AI prompts.

**The goal:** load Contoso retail data from a Fabric Lakehouse (bronze) through dbt transformations (silver → gold → serving), ending with a region-filtered view and passing dbt tests.

---

## Architecture Summary

```
Lakehouse (contoso_lakehouse) — Bronze Delta tables
        ↓  cross-database SQL
Warehouse (contoso_warehouse) — dbt target
        ↓
silver schema → gold schema → serving schema (views)
```

---

## Stack

| Component | Technology |
|---|---|
| Bronze storage | Microsoft Fabric Lakehouse (Delta tables) |
| Transformation target | Microsoft Fabric Warehouse |
| Transformations + tests | dbt + dbt-fabric adapter |
| Workspace/resource setup | fab-cli (Fabric REST API CLI) |
| Ingestion | PySpark notebook + Fabric Data Pipeline |

---

## Key Paths & Names

| Item | Value |
|---|---|
| Lakehouse name | `contoso_lakehouse` |
| Warehouse name | `contoso_warehouse` |
| Bronze tables location | Lakehouse `dbo` schema, prefix `bronze_` |
| Raw parquet files | `contoso_lakehouse/Files/raw/parquet/` |
| dbt project root | `dbt/` |
| dbt profile name | `contoso_fabric_dbt` |

---

## Layer Definitions

| Layer | Schema | Materialization | Naming |
|---|---|---|---|
| Bronze | Lakehouse `dbo` | Delta table (written by notebook) | `bronze_{entity}` |
| Silver | Warehouse `silver` | `table` | `stg_{entity}` |
| Gold | Warehouse `gold` | `table` | `fct_{name}` / `dim_{name}` |
| Serving | Warehouse `serving` | `view` | `{continent_lc}_{gold_model}` |

---

## Critical Fabric Quirks — Read These

### 1. Cross-database source (Lakehouse → Warehouse)
Bronze tables live in the **Lakehouse SQL endpoint**. dbt runs against the **Warehouse SQL endpoint**. These are different connections.

In dbt, bronze tables are defined as a **source** with `database: contoso_lakehouse`:

```yaml
sources:
  - name: bronze
    database: contoso_lakehouse
    schema: dbo
    tables:
      - name: bronze_sales
      - name: bronze_customer
      - name: bronze_product
      - name: bronze_store
      - name: bronze_date
```

Reference in models: `{{ source('bronze', 'bronze_sales') }}`

### 2. dbt target is the Warehouse, not the Lakehouse
The `profiles.yml` server is the **Warehouse SQL endpoint**:
```
<workspace-id>.datawarehouse.fabric.microsoft.com
```
Never use the Lakehouse SQL endpoint as the dbt target.

### 3. Three-part naming
From the Warehouse, Lakehouse tables are reachable as:
`contoso_lakehouse.dbo.bronze_sales`

### 4. Schema prefixing
dbt-fabric may prefix schema names. If your models land in `dbo_silver` instead of `silver`, set `+schema_suffix_connector: ''` or configure accordingly in `dbt_project.yml`.

---

## dbt Project Structure

```
dbt/
├── dbt_project.yml          # Project config, materialization defaults
├── profiles.yml.example     # Connection template (no real credentials)
├── models/
│   ├── silver/
│   │   ├── _silver.yml      # Sources + schema tests
│   │   ├── stg_sales.sql
│   │   ├── stg_customer.sql
│   │   ├── stg_product.sql
│   │   └── stg_store.sql
│   ├── gold/
│   │   ├── _gold.yml
│   │   └── fct_sales.sql
│   └── serving/
│       ├── _serving.yml
│       └── europe_fct_sales.sql
└── tests/
    └── assert_serving_matches_bronze_rowcount.sql
```

---

## Materialization Defaults (`dbt_project.yml`)

```yaml
models:
  contoso_fabric_dbt:
    silver:
      +materialized: table
      +schema: silver
    gold:
      +materialized: table
      +schema: gold
    serving:
      +materialized: view
      +schema: serving
```

---

## Silver Models — Rules

- Select from `{{ source('bronze', 'bronze_*') }}`
- Cast columns to correct types (dates → `DATE`, numerics → correct precision)
- Rename to `snake_case` if needed
- **No business logic** — that belongs in gold
- Required: preserve `continent` column in `stg_customer`

---

## Gold Model — `fct_sales`

Join silver tables. Use `LEFT JOIN` for all dimension joins (prevent row loss from unmatched keys).

Required output columns: `order_key`, `line_number`, `order_date`, `delivery_date`, `quantity`, `unit_price`, `net_price`, `unit_cost`, `customer_key`, `continent`, `product_key`, `product_name`, `category`, `store_key`, `store_name`

---

## Serving Model — `europe_fct_sales`

```sql
SELECT * FROM {{ ref('fct_sales') }}
WHERE continent = 'Europe'
```

Materialized as `view`. Naming convention: `{continent_lowercase}_{gold_model}`.

> ⚠️ Verify the exact `continent` value by running:
> `SELECT DISTINCT continent FROM silver.stg_customer`

---

## Tests

**Schema tests** (defined in `.yml` files):
- `not_null` on `order_key`, `customer_key`, `product_key`, `store_key`, `order_date` (silver)
- `not_null` on `continent` in `stg_customer`

**Custom singular test** (`tests/assert_serving_matches_bronze_rowcount.sql`):
- Returns rows only when bronze European order count ≠ serving view count
- Passes when query returns 0 rows (standard dbt singular test behavior)
- Failure usually means duplicate rows from a bad join — check for `INNER JOIN` vs `LEFT JOIN`

---

## What NOT to Do

- ❌ Do not add business logic in silver models
- ❌ Do not hardcode connection strings — use `profiles.yml.example` with placeholders
- ❌ Do not commit real credentials or workspace IDs
- ❌ Do not use the Lakehouse SQL endpoint as the dbt `target`
- ❌ Do not use `INNER JOIN` for dimension joins in `fct_sales` (use `LEFT JOIN`)
