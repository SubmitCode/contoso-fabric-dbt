# AGENTS.md — AI Agent Context

> **Read this first.** Share this file with your AI coding agent before asking it to implement
> anything in this project. It contains everything the agent needs to work on this codebase
> without asking follow-up questions.

---

## Project Purpose

A public, reproducible Microsoft Fabric + dbt challenge using Contoso V2 open retail data.
Participants build a complete data pipeline using only AI prompts — from an empty Fabric tenant
to a fully tested medallion architecture.

**Business goal:** The Contoso regional analytics team needs a self-service view of retail sales
by region. The European sales team is first. The pipeline must be clean, tested, and extensible
so other regions can be added with minimal effort.

**The goal:** Provision Fabric resources, load Contoso retail data into a Lakehouse (bronze),
transform through dbt (silver → gold → serving), deliver a region-filtered view, and pass all
dbt tests — using only AI prompts.

---

## Architecture Summary

```
[Nothing] — start from scratch
        ↓  fab-cli
Fabric Workspace
        ↓  fab-cli
Lakehouse (contoso_lakehouse) + Warehouse (contoso_warehouse)
        ↓  Fabric Notebook (pandas-bridge ingestion)
Bronze Delta tables in Lakehouse dbo schema
        ↓  cross-database SQL
Warehouse (dbt target)
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
| Workspace/resource setup | fab-cli (ms-fabric-cli) |
| Ingestion | Fabric Notebook (pandas + PySpark) |

---

## Key Names — Use These Exactly

These names are hardcoded into dbt source definitions. Use them as-is.

| Item | Value |
|---|---|
| Workspace name | your choice — note it for dbt config |
| Lakehouse name | `contoso_lakehouse` |
| Warehouse name | `contoso_warehouse` |
| Bronze tables schema | Lakehouse `dbo` |
| Bronze table prefix | `bronze_` |
| dbt project root | `dbt/` |
| dbt profile name | `contoso_fabric_dbt` |

---

## Provisioning — Phase 0

Start from scratch. Use `fab`-cli to create all resources.

```bash
# Authenticate
fab auth login   # opens browser — select "Interactive with a web browser"

# Create workspace (choose your own name)
fab mkdir <YourWorkspaceName>.Workspace

# Create Lakehouse
fab mkdir "<YourWorkspaceName>.Workspace/contoso_lakehouse.Lakehouse"

# Create Warehouse
fab mkdir "<YourWorkspaceName>.Workspace/contoso_warehouse.Warehouse"
```

After creation, find your Warehouse SQL endpoint in the Fabric UI:
**Warehouse → Settings → SQL connection string**

It looks like: `<workspace-id>.datawarehouse.fabric.microsoft.com`

---

## Ingestion — Phase 1

Upload and run the provided notebook:

```bash
# Import the notebook into your workspace
fab import "<YourWorkspaceName>.Workspace/01_ingest_contoso.Notebook" \
  -i ./notebooks --format .ipynb -f

# Run it (synchronous — waits for completion)
fab job run "<YourWorkspaceName>.Workspace/01_ingest_contoso.Notebook"
```

The notebook uses the **pandas-bridge pattern** — it reads parquet files with pandas on the driver
node (no ABFS auth needed), then writes Delta tables via `saveAsTable()`. This is required because
`spark.read.parquet()` on local `/tmp` paths fails in Fabric due to ABFS auth even for local files.

After the notebook runs, these bronze tables exist in `contoso_lakehouse.dbo`:
- `bronze_sales` (~223,974 rows)
- `bronze_customer`
- `bronze_product`
- `bronze_store`
- `bronze_date`
- `bronze_currency_exchange`

---

## dbt Setup — Phase 2

### Install dependencies
```bash
pip install dbt-fabric
```

### Authentication
dbt-fabric uses Azure CLI for authentication (`authentication: CLI` in profiles.yml).

```bash
# Install Azure CLI if needed
pip install azure-cli

# Login — use device code in headless/terminal environments
az login --use-device-code
```

The device code flow prints a URL and a code. Open the URL in any browser, enter the code.
No browser launch required on the machine running dbt.

### Configure profiles.yml
```bash
cp dbt/profiles.yml.example ~/.dbt/profiles.yml
# Edit: replace <your-workspace-id> with your Warehouse SQL endpoint prefix
```

### Verify connection
```bash
cd dbt && dbt debug
```

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
Bronze tables live in the **Lakehouse SQL endpoint**. dbt runs against the **Warehouse SQL endpoint**.
These are different connections. The Warehouse queries the Lakehouse via three-part naming:
`contoso_lakehouse.dbo.bronze_sales`

In dbt, define bronze tables as a source with `database: contoso_lakehouse`:

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

### 3. Schema naming
dbt-fabric may prefix schema names (e.g. `dbo_silver` instead of `silver`). There is a known fix
involving a custom `generate_schema_name` macro — see `HINTS.md` if your models land in the wrong
schema.

### 4. Bronze column names are CamelCase
All Contoso V2 bronze columns use CamelCase: `OrderKey`, `CustomerKey`, `ProductKey`, `StoreKey`,
`OrderDate`, `DeliveryDate`, `Quantity`, `UnitPrice`, `NetPrice`, `UnitCost`, `Continent`,
`ProductName`, `CategoryName`, `SubCategoryName`.

Silver models are where you rename to `snake_case` using CAST + alias.

When writing SQL that queries bronze tables directly (e.g. in custom dbt tests), always use the
original CamelCase column names.

### 5. Store name column
The human-readable store name (e.g. "Contoso Store Australian Capital Territory") is in the
`Description` column of `bronze_store`, not `StoreName` or `CountryName`.

### 6. LEFT JOIN for dimension joins
Use `LEFT JOIN` (not `INNER JOIN`) for all dimension joins in `fct_sales`. Inner joins will drop
sales rows that have unmatched dimension keys, causing the row count test to fail.

---

## dbt Project Structure

```
dbt/
├── dbt_project.yml          # Project config, materialization defaults
├── profiles.yml.example     # Connection template (no real credentials)
├── models/
│   ├── silver/
│   │   ├── _silver.yml      # Sources + schema tests
│   │   ├── stg_sales.sql    # stub — implement this
│   │   ├── stg_customer.sql # stub — implement this
│   │   ├── stg_product.sql  # stub — implement this
│   │   └── stg_store.sql    # stub — implement this
│   ├── gold/
│   │   ├── _gold.yml
│   │   └── fct_sales.sql    # stub — implement this
│   └── serving/
│       ├── _serving.yml
│       └── europe_fct_sales.sql  # stub — implement this
└── tests/
    └── assert_serving_matches_bronze_rowcount.sql  # stub — implement this
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
- Cast columns to correct types (dates → `DATE`, numerics → appropriate precision)
- Rename to `snake_case`
- **No business logic** — that belongs in gold
- Required: preserve `continent` column in `stg_customer`

---

## Gold Model — `fct_sales`

Join all silver tables. Use `LEFT JOIN` for all dimension joins.

Required output columns: `order_key`, `line_number`, `order_date`, `delivery_date`, `quantity`,
`unit_price`, `net_price`, `unit_cost`, `customer_key`, `continent`, `product_key`, `product_name`,
`category`, `store_key`, `store_name`

---

## Serving Model — `europe_fct_sales`

```sql
SELECT * FROM {{ ref('fct_sales') }}
WHERE continent = 'Europe'
```

Materialized as `view`. Naming convention: `{continent_lowercase}_{gold_model}`.

Verify the exact continent value before hardcoding:
```sql
SELECT DISTINCT continent FROM silver.stg_customer ORDER BY 1
```

---

## Custom Test — `assert_serving_matches_bronze_rowcount`

A dbt singular test that validates the serving view row count matches the count of European orders
in bronze. Standard dbt singular test behaviour: **returns rows = fails, returns 0 rows = passes**.

The test joins `bronze_sales` and `bronze_customer` directly on their CamelCase key columns.

---

## What NOT to Do

- Do not add business logic in silver models
- Do not hardcode connection strings — use `profiles.yml.example` with placeholders
- Do not commit real credentials or workspace IDs
- Do not use the Lakehouse SQL endpoint as the dbt target
- Do not use `INNER JOIN` for dimension joins in `fct_sales`
- Do not use `spark.read.parquet()` on local `/tmp` paths in Fabric notebooks
