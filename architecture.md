# Architecture

## Overview

This project implements a **medallion architecture** on Microsoft Fabric using open Contoso retail
data. It is designed as a fully reproducible reference implementation and challenge kit.

The goal is to demonstrate how a modern data lakehouse can be built end-to-end on Fabric — from
provisioning resources and ingesting raw files to a tested, region-filtered serving layer — using
dbt for all transformations and AI prompts for all code.

**Audience:** Data Engineers and Analytics Engineers working with Microsoft Fabric and dbt.

---

## Data Flow

```
[Empty Fabric Tenant]
        │  fab-cli
        ▼
Fabric Workspace
        │  fab-cli
        ▼
Lakehouse: contoso_lakehouse        Warehouse: contoso_warehouse
/Files/ (optional staging)                    (dbt target)
        │
        │  Fabric Notebook (01_ingest_contoso.ipynb)
        │  pandas-bridge: pd.read_parquet() -> spark.createDataFrame() -> saveAsTable()
        ▼
Lakehouse Delta Tables — Bronze Layer (schema: dbo):
  bronze_sales       (~223,974 rows)
  bronze_customer
  bronze_product
  bronze_store
  bronze_date
  bronze_currency_exchange
        │
        │  cross-database SQL (contoso_lakehouse.dbo.bronze_*)
        ▼
Warehouse: contoso_warehouse
        │
  ┌─────┴──────────────────┐
  ▼                        │
silver schema (dbt)        │
  stg_sales                │
  stg_customer             │
  stg_product              │
  stg_store                │
        │                  │
        ▼                  │
gold schema (dbt)          │
  fct_sales ───────────────┘
  (joined: sales + customer + product + store)
        │
        ▼
serving schema (dbt views)
  europe_fct_sales
  (WHERE continent = 'Europe')
        │
        ▼ (stretch goal)
Fabric Semantic Model
```

---

## Layer Definitions

### Phase 0 — Provisioning
- **Tool:** `fab`-cli (ms-fabric-cli)
- **Creates:** Workspace, Lakehouse (`contoso_lakehouse`), Warehouse (`contoso_warehouse`)
- **Starting point:** Empty Fabric tenant with capacity

### Bronze (Fabric Lakehouse)
- **What:** Raw data exactly as downloaded — no transformations
- **Format:** Delta tables in the Lakehouse default schema (`dbo`)
- **Naming:** `bronze_{entity}` (e.g., `bronze_sales`)
- **Written by:** Fabric Notebook using pandas-bridge pattern
- **Note:** All column names are CamelCase (`OrderKey`, `CustomerKey`, `Continent`, etc.)

### Silver (Fabric Warehouse — dbt)
- **What:** Cleaned, typed, renamed staging tables — no business logic
- **Purpose:** Fix data types, standardize column names to snake_case, ensure nullability
- **Naming:** `stg_{entity}` (e.g., `stg_sales`)
- **Materialization:** `table`
- **Schema:** `silver`

### Gold (Fabric Warehouse — dbt)
- **What:** Joined, enriched fact tables ready for analytics
- **Purpose:** Combine dimension data into a wide fact table
- **Naming:** `fct_{name}` or `dim_{name}` (e.g., `fct_sales`)
- **Materialization:** `table`
- **Schema:** `gold`

### Serving (Fabric Warehouse — dbt views)
- **What:** Thin, region-filtered views on top of the Gold layer
- **Purpose:** Segment data for specific consumers or regions
- **Naming:** `{continent_lowercase}_{gold_model}` (e.g., `europe_fct_sales`)
- **Materialization:** `view`
- **Schema:** `serving`

---

## Dataset

**Source:** [Contoso Data Generator V2 — Ready to Use Data](https://github.com/sql-bi/Contoso-Data-Generator-V2-data/releases/tag/ready-to-use-data)

**Release used:** `parquet-100k` (~100,000 orders)

**Schema (star schema):**

| Table | Type | Key columns |
|---|---|---|
| `sales` | Fact | `OrderKey`, `LineNumber`, `OrderDate`, `DeliveryDate`, `CustomerKey`, `StoreKey`, `ProductKey`, `Quantity`, `UnitPrice`, `NetPrice`, `UnitCost` |
| `customer` | Dimension | `CustomerKey`, `Continent`, `GeoAreaKey` |
| `product` | Dimension | `ProductKey`, `ProductName`, `CategoryName`, `SubCategoryName` |
| `store` | Dimension | `StoreKey`, `Description` (store name), `CountryCode` |
| `date` | Dimension | date keys, year, month, quarter |
| `currencyexchange` | Reference | exchange rate data |

Note: the archive file is `currencyexchange.parquet` (no underscore).

---

## Technology Stack

| Component | Technology | Purpose |
|---|---|---|
| **Lakehouse** | Microsoft Fabric Lakehouse (Delta) | Bronze layer storage |
| **Warehouse** | Microsoft Fabric Warehouse | Silver / Gold / Serving target |
| **Transformations** | dbt + dbt-fabric adapter | All SQL models + tests |
| **Workspace setup** | fab-cli (ms-fabric-cli) | Create Fabric resources via REST API |
| **Ingestion** | Fabric Notebook (pandas + PySpark) | Read parquet → write Delta tables |

---

## Naming Conventions

| Layer | Pattern | Example |
|---|---|---|
| Bronze (Lakehouse) | `bronze_{entity}` | `bronze_sales` |
| Silver | `stg_{entity}` | `stg_sales` |
| Gold (fact) | `fct_{name}` | `fct_sales` |
| Gold (dimension) | `dim_{name}` | `dim_product` |
| Serving | `{continent_lc}_{gold_model}` | `europe_fct_sales` |

---

## Prerequisites

- Microsoft Fabric workspace with capacity (or trial)
- Python 3.10+
- [fab-cli](https://github.com/microsoft/fabric-cli) (`pip install ms-fabric-cli`)
- [dbt-fabric](https://docs.getdbt.com/docs/core/connect-data-platform/fabric-setup) (`pip install dbt-fabric`)
- Azure CLI for dbt auth (`pip install azure-cli`)

---

## Quickstart (Challenge Mode)

1. **Read `AGENTS.md`** — share it with your AI agent before starting
2. **Provision** — use `fab`-cli to create workspace, Lakehouse, and Warehouse (Phase 0 in `CHALLENGE.md`)
3. **Ingest** — upload and run `notebooks/01_ingest_contoso.ipynb` in Fabric
4. **Configure dbt** — copy `dbt/profiles.yml.example` to `~/.dbt/profiles.yml`, fill in your Warehouse SQL endpoint
5. **Accept the challenge** — read `CHALLENGE.md`, then prompt your way to a green `dbt test` run
