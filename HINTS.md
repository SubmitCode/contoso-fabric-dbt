# Hints & Gotchas 💡

> These hints cover Fabric-specific quirks that have nothing to do with your skill level — just things that will cost you hours without a pointer. Consult freely; the challenge is in the prompting, not in knowing every API detail.

---

## Hint 1: How dbt Connects to Fabric

dbt-fabric connects to the **Warehouse SQL endpoint**, not the Lakehouse.

Your `profiles.yml` must point to the Warehouse. Find the connection string in the Fabric UI:
**Warehouse → Settings → SQL connection string**

It looks like:
```
<workspace-id>.datawarehouse.fabric.microsoft.com
```

The Lakehouse also has a SQL endpoint — but that's your **source**, not your dbt target.

---

## Hint 2: Reading Bronze Tables from the Lakehouse (Cross-Database Sources)

Bronze tables live in the **Lakehouse**, but dbt runs against the **Warehouse**. These are two different SQL endpoints.

The good news: Fabric supports cross-database queries natively. The Warehouse can query the Lakehouse via three-part naming:

```sql
[contoso_lakehouse].[dbo].[bronze_sales]
```

In dbt, define the Lakehouse tables as a **source** with the Lakehouse name as the `database`:

```yaml
# dbt/models/silver/_silver.yml
sources:
  - name: bronze
    database: contoso_lakehouse   # ← Lakehouse name (not Warehouse)
    schema: dbo
    tables:
      - name: bronze_sales
      - name: bronze_customer
      ...
```

Then reference them in your models with `{{ source('bronze', 'bronze_sales') }}`.

---

## Hint 3: Bronze Table Names & Location

The ingestion notebook writes Delta tables to the Lakehouse with a `bronze_` prefix, in the default schema (`dbo`).

Full three-part names from the Warehouse:
- `contoso_lakehouse.dbo.bronze_sales`
- `contoso_lakehouse.dbo.bronze_customer`
- `contoso_lakehouse.dbo.bronze_product`
- `contoso_lakehouse.dbo.bronze_store`
- `contoso_lakehouse.dbo.bronze_date`

---

## Hint 4: Materializations in Fabric Warehouse

dbt-fabric supports `table` and `view` in the Warehouse. Recommended defaults:

| Layer | Materialization |
|---|---|
| Silver | `table` |
| Gold | `table` |
| Serving | `view` |

Set defaults per folder in `dbt_project.yml` to avoid repeating config in every model:

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

## Hint 5: The `continent` Column Lives in `customer`, Not `sales`

The `sales` table has `customer_key` — but no geographic information.

The `customer` table has the `continent` column. To filter by region in the serving layer, you need to join `fct_sales` (gold) which already includes `continent` from the customer join.

Confirm the exact values in your data:
```sql
SELECT DISTINCT continent FROM silver.stg_customer ORDER BY 1;
```

Expected values include: `Europe`, `North America`, `Asia`, etc. Use the exact string in your `WHERE` clause.

---

## Hint 6: Running dbt Commands

```bash
# From the dbt/ folder:
dbt run                        # run all models
dbt run --select silver        # run only silver layer
dbt run --select fct_sales     # run one model
dbt test                       # run all tests
dbt test --select silver       # test one layer
dbt compile                    # compile SQL without running (good for debugging)
dbt docs generate && dbt docs serve  # browse lineage in browser
```

---

## Hint 7: How the Custom Row Count Test Works

The file `tests/assert_serving_matches_bronze_rowcount.sql` is a **dbt singular test**.

Singular tests work like this: **if the query returns any rows, the test fails.** The query is written to return rows only when there's a discrepancy — so returning 0 rows = test passes.

If your test fails, check for:
- **Duplicate rows** from joins — use `LEFT JOIN` for dimension tables, not `INNER JOIN`
- **Mismatched filter** — the `continent` value in the test must exactly match the value in your serving view's `WHERE` clause

---

## Hint 8: Recommended Prompt Strategy for Your AI Agent

Give context before asking for code. This saves many iterations:

1. **Share `CLAUDE.md` first** — it contains the full project context, naming conventions, and known gotchas. Start your session with: *"Read this file before we begin."*
2. **Then share the specific model stub** you want implemented
3. **Ask the agent to explain its plan** before writing — catch misunderstandings early
4. **Run `dbt compile` before `dbt run`** — it catches SQL syntax errors without hitting the database
5. **Iterate on one layer at a time** — get silver green before starting gold

---

## Still stuck?

Open an issue in this repo describing where you're blocked. Chances are someone else hit the same wall.
