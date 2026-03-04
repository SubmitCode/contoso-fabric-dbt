# Architecture

## Overview

This project implements a **medallion architecture** on Microsoft Fabric using open Contoso retail data. It is designed as a fully reproducible reference implementation and challenge kit.

The goal is to demonstrate how a modern data lakehouse can be built end-to-end on Fabric — from raw file ingestion to a tested, region-filtered serving layer — using dbt for all transformations.

**Audience:** Data Engineers and Analytics Engineers working with Microsoft Fabric and dbt.

---

## Data Flow

```
Web (GitHub Releases)
        │  parquet-100k.7z (Contoso V2)
        ▼
[Fabric Data Pipeline]
  HTTP Source → download & extract → save to Lakehouse Files
        │
        ▼
Lakehouse: contoso_lakehouse
  /Files/raw/parquet/
  (sales.parquet, customer.parquet, product.parquet, store.parquet, date.parquet)
        │
        ▼
[Fabric Notebook: 01_ingest_contoso.ipynb]
  PySpark: read parquet → write Delta tables
        │
        ▼
Lakehouse Delta Tables — Bronze Layer:
  bronze_sales       (~100,000 rows)
  bronze_customer
  bronze_product
  bronze_store
  bronze_date
  bronze_currency_exchange
        │
        │  (cross-database query via Lakehouse SQL endpoint)
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
  stg_date                 │
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
        ▼ (optional)
Fabric Semantic Model
```

---

## Layer Definitions

### Bronze (Fabric Lakehouse)
- **What:** Raw data exactly as downloaded — no transformations
- **Format:** Delta tables in the Lakehouse default schema (`dbo`)
- **Naming:** `bronze_{entity}` (e.g., `bronze_sales`)
- **Written by:** PySpark notebook (01_ingest_contoso.ipynb)

### Silver (Fabric Warehouse — dbt)
- **What:** Cleaned, typed, renamed staging tables — no business logic
- **Purpose:** Fix data types, standardize column names, ensure nullability
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
| `sales` | Fact | `order_key`, `line_number`, `order_date`, `delivery_date`, `customer_key`, `store_key`, `product_key`, `quantity`, `unit_price`, `net_price`, `unit_cost` |
| `customer` | Dimension | `customer_key`, `continent`, `geo_area_key` |
| `product` | Dimension | `product_key`, `product_name`, `category`, `subcategory` |
| `store` | Dimension | `store_key`, `store_name`, `country` |
| `date` | Dimension | `date_key`, `date`, `year`, `month`, `quarter` |
| `currency_exchange` | Reference | exchange rate data |

---

## Technology Stack

| Component | Technology | Purpose |
|---|---|---|
| **Lakehouse** | Microsoft Fabric Lakehouse (Delta) | Bronze layer storage |
| **Warehouse** | Microsoft Fabric Warehouse | Silver / Gold / Serving target |
| **Transformations** | dbt + dbt-fabric adapter | All SQL models + tests |
| **Workspace setup** | fab-cli | Create Fabric resources via REST API |
| **Ingestion** | Fabric Notebook (PySpark) | Read parquet → write Delta tables |
| **Pipeline** | Fabric Data Pipeline | HTTP download → Lakehouse Files |

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
- [fab-cli](https://github.com/microsoft/fabric-cli) installed and authenticated
- [dbt-fabric](https://docs.getdbt.com/docs/core/connect-data-platform/fabric-setup) adapter installed

---

## Quickstart (5 Steps)

1. **Setup workspace** — run `scripts/00_setup_workspace.sh` to create the Fabric workspace
2. **Create resources** — run `scripts/01_create_resources.sh` to create the Lakehouse and Warehouse
3. **Ingest data** — upload and run `notebooks/01_ingest_contoso.ipynb` in Fabric to load bronze tables
4. **Configure dbt** — copy `dbt/profiles.yml.example` to `~/.dbt/profiles.yml` and fill in your Warehouse SQL endpoint
5. **Accept the challenge** — read `CHALLENGE.md` and start prompting
