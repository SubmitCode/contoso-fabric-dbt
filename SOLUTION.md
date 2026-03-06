# Solution — From Prompt to Gold

> This file documents the complete solution for the Contoso Fabric dbt challenge.
> It lives on the `feat/solution` branch only and is not part of the challenge kit.

---

## Result

**19/19 dbt tests passing. All 6 models running. Full medallion pipeline end-to-end.**

```
PASS=19  WARN=0  ERROR=0  SKIP=0  TOTAL=19
```

---

## Resources Provisioned

| Resource   | Name                  | ID                                     |
|------------|-----------------------|----------------------------------------|
| Workspace  | contoso-challenge     | `39475fe3-20a6-4f64-b7e5-9b45a536406b` |
| Capacity   | fabricdatacoe         | `5190c581-5cac-4f39-998b-c1e5614652bf` |
| Lakehouse  | contoso_lakehouse     | `e15fc533-c44a-42e8-9a58-c3ea59eeccf5` |
| Warehouse  | contoso_warehouse     | `3485906c-1613-4b7d-b20d-d1e493861334` |

Warehouse SQL endpoint:
```
zlhoxuko56xulc6qxwe2ozcrza-4npuoongebse7n7ftnc2knsanm.datawarehouse.fabric.microsoft.com
```

Auth account: `cfwi@nimbusplane.io`, tenant: `d1ebceca-ef4e-45af-8bd0-bd89a76451c8`

---

## Session Summary

This solution was built entirely through AI prompts using Claude Code (claude-sonnet-4-6), with zero
manual code editing. The session covered provisioning, ingestion, all dbt layers, and debugging —
end-to-end from an empty Fabric tenant to 19/19 green tests.

### Phase 0 — Fabric Resource Provisioning

Used `fab` CLI (ms-fabric-cli) to create workspace, Lakehouse, and Warehouse via Fabric REST API.

Key commands:
```bash
python3 -c "from fabric_cli.main import main; ..." auth login   # browser-based user auth
python3 -c "from fabric_cli.main import main; ..." mkdir contoso-challenge.Workspace
# Lakehouse and Warehouse created via fabric_cli Python API directly
```

Note: `~/.local/bin/fab` was shadowed by the `fabric` task-runner package. The real ms-fabric-cli
entry point had to be invoked via `python3 -c "from fabric_cli.main import main; ..."`.

### Phase 1 — Ingestion (Bronze Layer)

**Discovery 1: `spark.read.parquet()` on `/tmp` fails in Fabric notebooks.**

Even with a local path, Spark routes through ABFS (Azure Blob Filesystem). The session identity in a
notebook job cannot acquire ABFS storage credentials for local paths, so reads fail.

**Fix: The pandas-bridge pattern.**
```python
pdf = pd.read_parquet("/tmp/contoso/sales.parquet")   # pandas reads driver-locally, no auth needed
df  = spark.createDataFrame(pdf)                       # convert in-memory
df.write.format("delta").mode("overwrite").saveAsTable("bronze_sales")  # requires notebook context
```

**Discovery 2: `saveAsTable()` does not work in Livy API sessions.**

Livy sessions lack the MWC (Managed Workspace Credential) token required to write to the Lakehouse
metastore. All Delta writes must happen in a notebook job context, not a Livy session.

**Discovery 3: `currencyexchange.parquet` — no underscore.**

The archive extracts as `currencyexchange.parquet`, not `currency_exchange.parquet`. The table
mapping must account for this explicitly.

**Bronze tables loaded:**
- `bronze_sales`: 223,974 rows
- `bronze_customer`, `bronze_product`, `bronze_store`, `bronze_date`, `bronze_currency_exchange`

### Phase 2 — dbt Setup

- Installed `dbt-fabric` adapter, configured `~/.dbt/profiles.yml` with Warehouse SQL endpoint
- dbt authenticates via Azure CLI (`az login --use-device-code`) — CLI auth mode in `profiles.yml`
- `az` was installed via `pip install azure-cli` as `~/.local/bin/az`
- `dbt debug` confirmed connection OK

### Phase 3 — Silver Layer

Implemented `stg_sales`, `stg_customer`, `stg_product`, `stg_store`.

**Discovery 4: Bronze columns are CamelCase.**

All Contoso V2 bronze columns use CamelCase: `OrderKey`, `CustomerKey`, `Continent`, `CategoryName`,
`Description` (store name), etc. Silver models rename to `snake_case` via CAST + alias.

**Discovery 5: Store name is `Description`, not `StoreName` or `CountryName`.**

The `bronze_store` table has no `StoreName` column. The human-readable store name
(e.g. "Contoso Store Australian Capital Territory") is in the `Description` column.

13/13 silver schema tests passed on first run after fixing CamelCase references.

### Phase 4 — Gold Layer (`fct_sales`)

Joined all four silver tables. Used `LEFT JOIN` for all dimension joins to prevent row loss from
unmatched keys (critical — `INNER JOIN` causes row count mismatch in the singular test).

### Phase 5 — Serving Layer (`europe_fct_sales`)

Simple `SELECT * FROM {{ ref('fct_sales') }} WHERE continent = 'Europe'`.

Confirmed continent value by querying `SELECT DISTINCT continent FROM silver.stg_customer`.

### Phase 6 — Schema Prefix Fix

**Discovery 6: dbt-fabric prefixes schema names with `dbo_` by default.**

Models landed in `dbo_silver`, `dbo_gold`, `dbo_serving` instead of `silver`, `gold`, `serving`.

**Fix: custom `generate_schema_name` macro.**
```sql
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
```

This overrides dbt's default behaviour of prepending the target schema to custom schema names.

### Phase 7 — Final Test Fix

**Discovery 7: Singular test referenced lowercase bronze column names.**

`assert_serving_matches_bronze_rowcount.sql` used `s.customer_key` and `c.continent` directly
against bronze source tables. Bronze columns are CamelCase, so these returned
`Invalid column name 'customer_key'`.

**Fix:** Change to `s.CustomerKey`, `c.CustomerKey`, `c.Continent` in the test SQL.

After this fix: **19/19 tests passed**.

---

## Prompt Strategy

1. **Share `AGENTS.md` first** — essential project context before any code request
2. **One layer at a time** — silver green before gold, gold before serving
3. **Ask for plan before code** — caught the `INNER JOIN` vs `LEFT JOIN` issue before it ran
4. **Use `dbt compile` before `dbt run`** — catches SQL errors without a round-trip to Fabric
5. **Iterate on errors directly** — paste the error message verbatim, ask for targeted fix

Total iterations to green: ~12 prompt exchanges across all phases.

---

## Key Discoveries (Summary)

| # | Discovery | Impact |
|---|-----------|--------|
| 1 | `spark.read.parquet("/tmp/...")` fails — ABFS auth error | Used pandas-bridge pattern instead |
| 2 | `saveAsTable()` fails in Livy sessions — no MWC token | Must use notebook job context |
| 3 | Archive filename: `currencyexchange.parquet` (no underscore) | Explicit filename mapping |
| 4 | Bronze columns are CamelCase (`OrderKey`, `Continent`, etc.) | All SQL against bronze uses CamelCase |
| 5 | Store name is `Description` column, not `StoreName` | Mapped `Description AS store_name` in silver |
| 6 | dbt-fabric prefixes schemas with `dbo_` by default | Added `generate_schema_name` macro |
| 7 | `az login` needed for dbt CLI auth; use `--use-device-code` in headless terminals | Documented in HINTS.md |
| 8 | `fab auth login` uses browser popup, not device code | Use service principal or env var tokens in CI |

---

## Files Changed vs Challenge Kit (main branch)

| File | Change |
|------|--------|
| `dbt/models/silver/stg_sales.sql` | Full implementation |
| `dbt/models/silver/stg_customer.sql` | Full implementation |
| `dbt/models/silver/stg_product.sql` | Full implementation |
| `dbt/models/silver/stg_store.sql` | Full implementation |
| `dbt/models/gold/fct_sales.sql` | Full implementation (LEFT JOINs) |
| `dbt/models/serving/europe_fct_sales.sql` | Full implementation |
| `dbt/tests/assert_serving_matches_bronze_rowcount.sql` | CamelCase column fix |
| `dbt/macros/generate_schema_name.sql` | New — schema prefix fix |
| `notebooks/01_ingest_contoso.ipynb` | pandas-bridge pattern, filename mapping fix |
| `AGENTS.md` | Full rewrite for scratch scenario |
| `CHALLENGE.md` | New scenario, business goal, Phase 0 |
| `HINTS.md` | Auth hints, schema prefix hint, skills note |
