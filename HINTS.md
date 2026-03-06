# Hints & Gotchas

> These hints cover Fabric-specific quirks that have nothing to do with your skill level —
> just things that will cost you hours without a pointer. Consult freely; the challenge is
> in the prompting, not in knowing every API detail.

---

## Hint 0: Authentication — Read Before Starting

There are two separate auth flows in this project and they work differently.

**Use interactive or device code authentication only. Do not use service principals.**
Credentials should never be stored in files or passed to your AI agent. See the security
note in `README.md`.

### fab-cli auth (for provisioning)

```bash
fab auth login
```

This opens a **browser popup** and authenticates as your own user account. This is the
recommended approach — no credentials to manage.

There is no device code flow in `fab auth login`. If you are in a headless terminal without
a browser on the same machine, open the browser on any device and complete the login there,
or use pre-acquired tokens via environment variables (`FAB_TOKEN`, `FAB_TOKEN_ONELAKE`,
`FAB_TOKEN_AZURE`) — but never store them in files you share with your agent.

### Azure CLI auth (for dbt)

dbt-fabric authenticates via Azure CLI (`authentication: CLI` in `profiles.yml`). In a
**terminal or headless environment**, use the device code flow:

```bash
az login --use-device-code
```

This prints a URL and a short code. Open the URL in any browser on any device, enter the
code. No browser needs to launch on the machine running dbt. This is the recommended
approach for terminal use.

### Summary

| Tool | Recommended method | Notes |
|------|--------------------|-------|
| `fab auth login` | Browser popup (interactive) | No device code — must have browser access |
| `az login` | `az login --use-device-code` | Works in any terminal, browser on any device |

**Not recommended:** service principal auth. Credentials must be stored somewhere and will
inevitably be read by your AI agent. Use your own identity instead.

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

Bronze tables live in the **Lakehouse**, but dbt runs against the **Warehouse**. These are two
different SQL endpoints.

Fabric supports cross-database queries natively. The Warehouse can query the Lakehouse via
three-part naming:

```sql
[contoso_lakehouse].[dbo].[bronze_sales]
```

In dbt, define the Lakehouse tables as a **source** with the Lakehouse name as the `database`:

```yaml
# dbt/models/silver/_silver.yml
sources:
  - name: bronze
    database: contoso_lakehouse   # <- Lakehouse name (not Warehouse)
    schema: dbo
    tables:
      - name: bronze_sales
      - name: bronze_customer
      ...
```

Then reference them in your models with `{{ source('bronze', 'bronze_sales') }}`.

---

## Hint 3: Bronze Table Names & Location

The ingestion notebook writes Delta tables to the Lakehouse with a `bronze_` prefix in the
default schema (`dbo`).

Full three-part names from the Warehouse:
- `contoso_lakehouse.dbo.bronze_sales`
- `contoso_lakehouse.dbo.bronze_customer`
- `contoso_lakehouse.dbo.bronze_product`
- `contoso_lakehouse.dbo.bronze_store`
- `contoso_lakehouse.dbo.bronze_date`

Bronze columns are **CamelCase**: `OrderKey`, `CustomerKey`, `ProductKey`, `StoreKey`,
`OrderDate`, `DeliveryDate`, `Quantity`, `UnitPrice`, `NetPrice`, `UnitCost`, `Continent`,
`ProductName`, `CategoryName`, `SubCategoryName`.

Silver models are where you rename to `snake_case`. When writing SQL that queries bronze
directly (e.g. in a custom test), always use the original CamelCase names.

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

The `customer` table has the `continent` column. To filter by region in the serving layer,
you need to join through `fct_sales` (gold) which already includes `continent` from the
customer join.

Confirm the exact values in your data:
```sql
SELECT DISTINCT continent FROM silver.stg_customer ORDER BY 1;
```

Expected values: `Australia`, `Europe`, `North America`. Use the exact string in your `WHERE` clause.

---

## Hint 6: Store Name Is in the `Description` Column

The `bronze_store` table does not have a `StoreName` column. The human-readable store name
(e.g. "Contoso Store Australian Capital Territory") is in the `Description` column.

Map it in your silver model as: `CAST(Description AS VARCHAR(200)) AS store_name`

---

## Hint 7: Running dbt Commands

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

## Hint 8: How the Custom Row Count Test Works

The file `dbt/tests/assert_serving_matches_bronze_rowcount.sql` is a **dbt singular test**.

Singular tests work like this: **if the query returns any rows, the test fails.** Write the
query so it returns rows only when there is a discrepancy. Returning 0 rows = test passes.

If your test fails, check for:
- **Duplicate rows** from joins — use `LEFT JOIN` for dimension tables, not `INNER JOIN`
- **Mismatched filter** — the `continent` value must exactly match
- **CamelCase columns** — when querying bronze directly, use `CustomerKey` not `customer_key`

---

## Hint 9: Models Landing in the Wrong Schema (`dbo_silver` instead of `silver`)

dbt-fabric's default behaviour is to prepend the target schema name to any custom schema,
resulting in `dbo_silver`, `dbo_gold`, `dbo_serving` instead of `silver`, `gold`, `serving`.

**Fix:** Add a custom `generate_schema_name` macro to `dbt/macros/generate_schema_name.sql`:

```sql
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
```

This tells dbt to use the custom schema name as-is without prepending the target schema.

---

## Hint 10: Advanced — Use the Livy API to Test Code Before Running a Full Notebook Job

Notebook jobs in Fabric are relatively slow to start and synchronous — you don't want to run a
full ingestion job just to test whether a single cell works. For iterative development, use a
**Livy API session** to execute code interactively against a live Spark cluster, then promote
working code into the notebook.

### What Livy is good for (in this context)

- Testing a pandas-bridge snippet against a small sample before committing it to the notebook
- Inspecting bronze table schema, row counts, or sample values after ingestion
- Verifying column names and data types before writing silver models
- Running one-off `spark.sql(...)` queries against existing Delta tables

### What Livy cannot do (hard limits)

- `saveAsTable()` — fails, no MWC token in Livy sessions
- `spark.read.parquet("/tmp/...")` — fails, ABFS auth issue
- Any write to the Lakehouse — use a notebook job for all writes

### Workflow

```
1. Open a Livy session  →  test logic interactively (read-only or in-memory)
2. Confirm the code works
3. Paste working code into the notebook cells
4. Run the full notebook job via: fab job run "Workspace/Notebook.Notebook"
```

### Starting a Livy session (via Fabric REST API)

Livy sessions are started against the Spark pool associated with your Lakehouse. The endpoint
and session management are covered in the Fabric documentation:

```
https://learn.microsoft.com/en-us/fabric/data-engineering/livy-api
```

Your AI agent can help you construct the API calls — point it at the `fabric-notebook` skill
and ask it to set up a Livy session for interactive testing.

### Example: inspect a bronze table via Livy

```python
# Safe to run in a Livy session — read-only spark.sql
spark.sql("SELECT COUNT(*) FROM contoso_lakehouse.dbo.bronze_sales").show()
spark.sql("DESCRIBE contoso_lakehouse.dbo.bronze_customer").show(50)
```

> See the `fabric-notebook` skill for the full capability matrix comparing Livy sessions
> vs notebook jobs.

---

## Hint 11: Recommended Prompt Strategy for Your AI Agent

Give context before asking for code. This saves many iterations:

1. **Share `AGENTS.md` first** — it contains the full project context, naming conventions,
   and known gotchas. Start your session with: *"Read AGENTS.md before we begin."*
2. **Share the `.opencode/skills/` directory** — the `fabric-cli` and `fabric-notebook` skills
   contain tested patterns for every step of provisioning and ingestion.
3. **Share the specific model stub** you want implemented
4. **Ask the agent to explain its plan** before writing — catch misunderstandings early
5. **Run `dbt compile` before `dbt run`** — it catches SQL syntax errors without hitting the database
6. **Iterate one layer at a time** — get silver green before starting gold

---

## Still Stuck?

Open an issue in this repo describing where you're blocked. Chances are someone else hit the same wall.
