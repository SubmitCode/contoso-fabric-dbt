# The Challenge: From Prompt to Gold

> *Can you build a production-ready data pipeline from nothing — using only AI prompts?*

---

## The Scenario

You are a data engineer joining a new team. There is nothing in Fabric yet — no workspace,
no Lakehouse, no Warehouse. Just an empty tenant and a business requirement.

**The business goal:** Contoso's regional analytics team needs a self-service view of retail
sales by region. The European sales team is first. They need clean, tested data they can
connect a dashboard to. The ANZ team is next — so the pipeline needs to be extensible.

Your job: build the full pipeline end-to-end, from provisioning Fabric resources to a passing
`dbt test` run, delivering a region-filtered serving view — using only AI prompts.

**The catch: you cannot write a single line of code manually.**

You can read files. You can talk to your AI agent. You can iterate. But your fingers don't
touch the keyboard for code.

---

## The Rules

1. **No manual code editing** — use AI coding agents only (Claude Code, GitHub Copilot, Cursor, etc.)
2. You may write prompts, provide context files, correct the AI, and iterate freely
3. You may read files to understand the structure
4. **All dbt tests must pass** at the end (`dbt test` — fully green)
5. The serving layer must match the acceptance criteria below

---

## What's Provided

| File/Folder | What it is |
|---|---|
| `notebooks/01_ingest_contoso.ipynb` | Downloads Contoso data and writes Delta tables to the Lakehouse (bronze). **Run this in Fabric.** |
| `dbt/` | dbt project skeleton: folder structure, `dbt_project.yml`, source definitions, model stubs |
| `.opencode/skills/` | Agent skills for `fab`-cli and Fabric notebook patterns |
| `AGENTS.md` | Context file for AI agents — share this with your agent first |
| `HINTS.md` | Fabric-specific gotchas — consult when stuck |
| `architecture.md` | Full architecture reference |

That's it. No scripts to run. No workspace pre-created. You figure out the provisioning.

---

## The Phases

### Phase 0 — Provision Fabric Resources

Starting from nothing, create:
- A Fabric **Workspace** (your choice of name)
- A Lakehouse named **`contoso_lakehouse`**
- A Warehouse named **`contoso_warehouse`**

Use `fab`-cli via AI prompts. The `.opencode/skills/fabric-cli` skill has everything you need.

### Phase 1 — Ingest Bronze Data

Upload and run the provided notebook to load Contoso retail data into the Lakehouse as Delta tables.

After this phase, six `bronze_*` tables exist in `contoso_lakehouse.dbo`.

### Phase 2 — Configure dbt

Install `dbt-fabric`, configure `~/.dbt/profiles.yml` with your Warehouse SQL endpoint, and
verify the connection with `dbt debug`.

### Phase 3 — Silver Layer — `dbt/models/silver/`

Implement the four staging models. Clean and type the raw bronze tables:

- `stg_sales` — from `bronze_sales`
- `stg_customer` — from `bronze_customer` (ensure `continent` column is present)
- `stg_product` — from `bronze_product`
- `stg_store` — from `bronze_store`

Silver rules: cast types, rename to `snake_case`. **No business logic.**

### Phase 4 — Gold Layer — `dbt/models/gold/`

Build `fct_sales` by joining all silver tables. Required output columns (minimum):

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

### Phase 5 — Serving Layer — `dbt/models/serving/`

Build `europe_fct_sales`: a view on `fct_sales` filtered to European customers only.

Naming convention for future views: `{continent_lowercase}_{gold_model}`

### Phase 6 — Tests

Implement the custom singular test in `dbt/tests/assert_serving_matches_bronze_rowcount.sql`.
It should validate that the row count in `europe_fct_sales` matches the count of European orders
in the bronze source.

---

## Acceptance Criteria

Your challenge is complete when **all of the following are true**:

- [ ] `dbt run` completes without errors (all 6 models)
- [ ] `dbt test` passes all tests — schema tests + custom singular test
- [ ] `europe_fct_sales` exists as a view in the `serving` schema of the Warehouse
- [ ] `europe_fct_sales` contains only rows where `continent = 'Europe'`
- [ ] Row count in `europe_fct_sales` matches the number of European orders in `bronze_sales`
- [ ] No null values in key columns (`order_key`, `customer_key`, `product_key`, `store_key`, `order_date`)

---

## Stretch Goals

These are intentionally harder. Attempt them after the core challenge is complete.

- **Add a second serving view** for another continent (follow the naming convention — `australia_fct_sales`)
- **Build `dim_product`** in the Gold layer — a clean product dimension with category rollups
- **Write a data quality test** that verifies `delivery_date >= order_date` for all rows in `fct_sales`
- **Add a `dim_store`** Gold model with a country-level row count or aggregation
- **Connect a Fabric Semantic Model** to the serving layer views
- **Schedule ingestion** — create a Fabric Data Pipeline that re-runs the notebook on a schedule

---

## How to Verify

```bash
cd dbt
dbt run
dbt test
```

All green = challenge complete.

---

## Tips

- **Share `AGENTS.md` with your agent first** — it contains project context, naming conventions,
  and known quirks. This single step saves the most time.
- **Check `HINTS.md`** before assuming a problem is your fault — many failures are Fabric quirks.
- **The `.opencode/skills/` directory** contains agent skills for `fab`-cli and notebook patterns.
  Share them with your agent at the start of each phase.
- **Iterate one layer at a time** — get silver green before starting gold.

---

## Share Your Results

Did you complete it? What was your prompt strategy? How many iterations did it take?

Open an issue or start a discussion on this repo — we'd love to hear how you approached it.
