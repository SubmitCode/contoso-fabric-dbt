---
name: fabric-notebook
description: Author and run Microsoft Fabric notebooks for data ingestion. Use this skill when the task involves writing PySpark/pandas notebook code, loading data into a Lakehouse, understanding Livy API limitations, or debugging ingestion failures in Fabric.
---

## Overview

This skill covers:
- Writing Fabric notebook code for data ingestion (PySpark + pandas)
- Critical Livy API limitations and when they apply
- The pandas-bridge pattern for loading parquet into Delta tables
- Uploading and running notebooks via `fab` CLI
- Common ingestion failure patterns and fixes

---

## Execution Contexts — Know the Difference

Fabric offers two ways to run notebook code programmatically. They have **different capabilities**.

| Capability | Notebook Job (`fab job run`) | Livy API Session |
|---|---|---|
| `saveAsTable()` | ✅ Works | ❌ Fails (no MWC token) |
| `spark.read.parquet("abfss://...")` | ✅ Works | ❌ Fails (ABFS auth failure) |
| `spark.read.parquet("/tmp/...")` | ❌ Fails | ❌ Fails |
| `pandas.read_parquet("/tmp/...")` | ✅ Works | ✅ Works |
| Write Delta via `spark.createDataFrame(pdf).write` | ✅ Works | ❌ Fails |
| Interactive exploration | Limited | ✅ Works |

**Rule of thumb:** For any ingestion that writes to a Lakehouse, always use a **notebook job** (not a Livy session).

---

## The Pandas-Bridge Ingestion Pattern

When reading local files (e.g. parquet downloaded to `/tmp`) inside a Fabric notebook job:

```python
import pandas as pd
from pyspark.sql import SparkSession

spark = SparkSession.builder.getOrCreate()

# Step 1: Read locally with pandas (no ABFS auth needed)
pdf = pd.read_parquet("/tmp/sales.parquet")

# Step 2: Convert to Spark DataFrame
df = spark.createDataFrame(pdf)

# Step 3: Write as Delta table to Lakehouse
df.write.mode("overwrite").format("delta").saveAsTable("bronze_sales")
```

**Why this works:**
- `pd.read_parquet()` reads from the driver's local filesystem — no ABFS/OneLake auth required.
- `spark.createDataFrame()` converts in-memory.
- `saveAsTable()` works in notebook context because the notebook session has a valid MWC (Managed Workspace Credential) token; Livy sessions do not.

**Why `spark.read.parquet("/tmp/...")` fails:**
- Even with a local path, Spark tries to resolve it via the distributed filesystem layer, which triggers ABFS auth that fails outside notebook context.

---

## Livy API — What It Cannot Do

The Fabric Livy API (`https://<host>/livyapi/...`) provides interactive Spark sessions but has significant restrictions:

### Hard Limitations
- **No `saveAsTable()`** — sessions lack the MWC token required to write to Lakehouse metastore.
- **No `spark.read.parquet()` on ABFS paths** — ABFS auth fails; the session identity cannot acquire storage credentials.
- **No `spark.read.parquet()` on `/tmp`** — Spark still routes through the distributed FS layer.

### What Livy Sessions Can Do
- Execute arbitrary Python/Scala/R code
- Read data already in memory or from public URLs
- Perform in-memory transformations
- Return results to the caller

### When to Use Livy
- Quick exploratory queries against already-loaded tables
- Running `spark.sql(...)` against tables that already exist
- Checking schema/row counts of existing Delta tables

---

## Notebook Structure for Ingestion

### Recommended cell layout

```python
# Cell 1 — Imports and config
import pandas as pd
import urllib.request
import os

TABLES = {
    "bronze_sales":      "sales.parquet",
    "bronze_customer":   "customer.parquet",
    "bronze_product":    "product.parquet",
    "bronze_store":      "store.parquet",
    "bronze_date":       "date.parquet",
}
```

```python
# Cell 2 — Download parquet files to /tmp
BASE_URL = "https://<your-source>/parquet/"
for table, fname in TABLES.items():
    urllib.request.urlretrieve(BASE_URL + fname, f"/tmp/{fname}")
    print(f"Downloaded {fname}")
```

```python
# Cell 3 — Load each file into Lakehouse as Delta table
from pyspark.sql import SparkSession
spark = SparkSession.builder.getOrCreate()

for table, fname in TABLES.items():
    pdf = pd.read_parquet(f"/tmp/{fname}")
    df = spark.createDataFrame(pdf)
    df.write.mode("overwrite").format("delta").saveAsTable(table)
    count = spark.table(table).count()
    print(f"{table}: {count} rows")
```

---

## Notebook Format Requirements for `fab import`

Fabric requires notebook `source` fields to be **lists of strings** (one string per line), not a single multiline string.

### Correct format
```json
"source": ["line1\n", "line2\n", "last line"]
```

### Incorrect format (will fail with `InvalidNotebookContent`)
```json
"source": "line1\nline2\nlast line"
```

### Fix script (run before `fab import`)
```python
import json

with open('notebook.ipynb', 'r', encoding='utf-8') as f:
    nb = json.load(f)

for cell in nb.get('cells', []):
    source = cell.get('source')
    if isinstance(source, str):
        lines = source.split('\n')
        cell['source'] = [line + '\n' if i < len(lines) - 1 else line
                          for i, line in enumerate(lines)]
    if cell.get('cell_type') == 'code':
        cell.setdefault('outputs', [])
        cell.setdefault('execution_count', None)

with open('notebook_fixed.ipynb', 'w', encoding='utf-8') as f:
    json.dump(nb, f, ensure_ascii=False, indent=1)
```

### Directory structure for import
```
my_notebook/
└── notebook-content.ipynb   ← fixed file must have this exact filename
```

```bash
fab import "MyWorkspace.Workspace/MyNotebook.Notebook" \
  -i ./my_notebook --format .ipynb -f
```

---

## Running a Notebook Job

```bash
# Synchronous — waits for completion, returns exit status
fab job run "contoso-challenge.Workspace/01_ingest_contoso.Notebook"

# Check status of a previous run
fab job status "contoso-challenge.Workspace/01_ingest_contoso.Notebook" --run-id <run-id>
```

Use `fab job run` (synchronous) for ingestion so you know when the tables are ready before running dbt.

---

## Verifying Tables After Ingestion

Use the Livy API or Fabric SQL endpoint to confirm tables loaded correctly:

```python
# Via Livy (interactive check only — no writes)
import requests, json

session_url = "https://<workspace-id>.pbidedicated.windows.net/webapi/capacities/.../..."
# ... (see Livy docs for session creation)

# Quick check via spark.sql in a Livy session
code = "spark.table('bronze_sales').count()"
```

Or query via the Warehouse SQL endpoint (simpler):
```sql
-- In Fabric SQL editor or via pyodbc
SELECT COUNT(*) FROM contoso_lakehouse.dbo.bronze_sales
```

---

## Contoso V2 Parquet File Inventory

When using the Contoso V2 `parquet-100k` dataset:

| Parquet file | Delta table name | ~Rows (100k variant) |
|---|---|---|
| `sales.parquet` | `bronze_sales` | 223,974 |
| `customer.parquet` | `bronze_customer` | varies |
| `product.parquet` | `bronze_product` | varies |
| `store.parquet` | `bronze_store` | varies |
| `date.parquet` | `bronze_date` | varies |
| `currencyexchange.parquet` | `bronze_currency_exchange` | varies |

**Important:** Archive extracts without underscores — `sales.parquet` not `sales_data.parquet`.

### Bronze table column naming
All Contoso V2 bronze columns are **CamelCase**: `OrderKey`, `CustomerKey`, `ProductKey`, `StoreKey`, `OrderDate`, `DeliveryDate`, `Quantity`, `UnitPrice`, `NetPrice`, `UnitCost`, `Continent`, `ProductName`, `CategoryName`, `SubCategoryName`.

- Store name is in the `Description` column (not `StoreName` or `CountryName`).
- `Continent` values: `Australia`, `Europe`, `North America`.

When referencing bronze columns in dbt tests or raw SQL, always use the original CamelCase names. Silver models are where you rename to `snake_case`.

---

## Troubleshooting

### `saveAsTable` fails in Livy session
**Symptom:** `AnalysisException: Unable to infer schema` or auth error on write.
**Fix:** Move the write logic into a notebook job (`fab job run`), not a Livy session.

### `spark.read.parquet("/tmp/...")` fails
**Symptom:** `java.io.FileNotFoundException` or ABFS auth error even for `/tmp` paths.
**Fix:** Use `pd.read_parquet("/tmp/...")` then `spark.createDataFrame(pdf)`.

### `InvalidNotebookContent` on import
**Symptom:** `fab import` fails saying it cannot convert source to `List[System.String]`.
**Fix:** Run the fix script above to convert `source` fields from strings to lists.

### Bronze column not found in dbt test
**Symptom:** `Invalid column name 'customer_key'` in a singular test that queries bronze directly.
**Fix:** Use CamelCase (`CustomerKey`, `Continent`) when querying bronze tables. Only silver+ models use `snake_case`.

---

## References

- [Fabric Notebook documentation](https://learn.microsoft.com/en-us/fabric/data-engineering/how-to-use-notebook)
- [Fabric Livy API](https://learn.microsoft.com/en-us/fabric/data-engineering/livy-api)
- [Delta Lake on Fabric](https://learn.microsoft.com/en-us/fabric/data-engineering/lakehouse-and-delta-tables)
- [Contoso Data Generator](https://github.com/microsoft/contoso-data-generator)
