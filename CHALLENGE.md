# The Challenge: From Prompt to Gold 🏆

> *Can you build a production-ready data pipeline without writing a single line of code?*

---

## The Scenario

You've just joined a data team. There's a Fabric workspace, a Lakehouse loaded with raw Contoso retail data, and a dbt project skeleton waiting for you.

Your job: get the data to the Gold layer — shaped, joined, tested — and deliver a serving view filtered by region.

**The catch: you cannot write a single line of code manually.**

You can read files. You can talk to your AI agent. You can iterate. But your fingers don't touch the keyboard for code.

---

## The Rules

1. **No manual code editing** — use AI coding agents only (Claude Code, GitHub Copilot, Cursor, etc.)
2. You may write prompts, provide context files, correct the AI, and iterate freely
3. You may read files to understand the structure
4. **All dbt tests must pass** at the end (`dbt test` — fully green)
5. The Gold and Serving layers must match the acceptance criteria below

---

## What's Provided (the Kit)

| File/Folder | What it is |
|---|---|
| `scripts/` | fab-cli scripts to create your Fabric workspace, Lakehouse, and Warehouse |
| `notebooks/01_ingest_contoso.ipynb` | Downloads Contoso data → writes Delta tables to Lakehouse (Bronze) |
| `pipelines/ingest_contoso.json` | Fabric Data Pipeline definition (HTTP → Lakehouse Files) |
| `dbt/` | dbt project skeleton: folder structure, `dbt_project.yml`, source definitions, model stubs |
| `HINTS.md` | Fabric-specific gotchas — consult when stuck |
| `architecture.md` | Full architecture reference |
| `CLAUDE.md` | Context file for AI agents — share this with your agent first |

---

## The Task

Implement the following using **only AI prompts**:

### 1. Silver Layer — `dbt/models/silver/`

Clean and type the raw bronze tables. At minimum implement:

- `stg_sales` — from `bronze_sales`
- `stg_customer` — from `bronze_customer` (ensure `continent` column is present and clean)
- `stg_product` — from `bronze_product`
- `stg_store` — from `bronze_store`

Silver models: cast types, rename to snake_case. **No business logic here.**

### 2. Gold Layer — `dbt/models/gold/`

Build `fct_sales` by joining silver tables. Required columns (minimum):

| Column | Source |
|---|---|
| `order_key` | stg_sales |
| `line_number` | stg_sales |
| `order_date` | stg_sales |
| `delivery_date` | stg_sales |
| `quantity` | stg_sales |
| `unit_price` | stg_sales |
| `net_price` | stg_sales |
| `unit_cost` | stg_sales |
| `customer_key` | stg_customer |
| `continent` | stg_customer |
| `product_key` | stg_product |
| `product_name` | stg_product |
| `category` | stg_product |
| `store_key` | stg_store |
| `store_name` | stg_store |

### 3. Serving Layer — `dbt/models/serving/`

Build a view named `europe_fct_sales` that filters `fct_sales` to European customers only.

Naming convention for future views: `{continent_lowercase}_{gold_model}`

---

## Acceptance Criteria

Your challenge is complete when **all of the following are true**:

- [ ] `dbt run` completes without errors
- [ ] `dbt test` passes all tests (schema tests + custom singular test)
- [ ] `europe_fct_sales` exists as a view in the `serving` schema of the Warehouse
- [ ] `europe_fct_sales` contains only rows where `continent = 'Europe'`
- [ ] Row count in `europe_fct_sales` matches the number of European orders in `bronze_sales`
- [ ] No null values in key columns (`order_key`, `customer_key`, `product_key`, `store_key`, `order_date`)

---

## Stretch Goals (optional)

- 🌍 Add a second serving view for another continent (follow the naming convention)
- 📦 Add a `dim_product` model in the Gold layer
- 🔍 Write a dbt test that validates no `order_date` values are in the future
- 📊 Connect a Fabric Semantic Model to the serving layer

---

## How to Verify

```bash
cd dbt
dbt run
dbt test
```

All green = challenge complete. 🟢

---

## Share Your Results

Did you complete it? What was your prompt strategy? How many iterations did it take?

Open an issue or start a discussion on this repo — we'd love to hear how you approached it.
