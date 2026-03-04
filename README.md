# From Prompt to Gold 🏆

> **A No-Code Data Engineering Challenge on Microsoft Fabric + dbt**

Can you build a production-ready data pipeline **without writing a single line of code**?

This repo is a starter kit for a hands-on challenge: load the open [Contoso V2](https://github.com/sql-bi/Contoso-Data-Generator-V2-data) retail dataset into a Microsoft Fabric Lakehouse, transform it through a medallion architecture using dbt, and deliver a clean Gold layer — all driven entirely by AI prompts.

---

## The Challenge

→ Read **[CHALLENGE.md](./CHALLENGE.md)** for the full brief, rules, and acceptance criteria.

→ Stuck? Check **[HINTS.md](./HINTS.md)** for Fabric-specific gotchas and tips.

---

## Architecture

```
Web (Contoso V2 — 100K orders)
        │
        ▼
[Data Pipeline] → Lakehouse Files /raw/parquet/
        │
        ▼
[Notebook] → Lakehouse Delta Tables (Bronze)
        │   bronze_sales, bronze_customer, bronze_product, bronze_store, bronze_date
        │
        ▼  dbt via Warehouse SQL endpoint
[silver] → stg_sales, stg_customer, stg_product, stg_store
        │
        ▼
[gold]   → fct_sales  (joined fact table)
        │
        ▼
[serving]→ europe_fct_sales  (region-filtered view)
```

Full details: [architecture.md](./architecture.md)

---

## Prerequisites

- Microsoft Fabric workspace (trial or capacity)
- Python 3.10+
- [fab-cli](https://github.com/microsoft/fabric-cli) (Fabric REST API CLI)
- [dbt-fabric](https://docs.getdbt.com/docs/core/connect-data-platform/fabric-setup) adapter

---

## Quickstart

```bash
# 1. Clone this repo
git clone https://github.com/SubmitCode/contoso-fabric-dbt.git
cd contoso-fabric-dbt

# 2. Create Fabric workspace + resources
bash scripts/00_setup_workspace.sh
bash scripts/01_create_resources.sh

# 3. Run the ingestion notebook in Fabric
#    Upload notebooks/01_ingest_contoso.ipynb to your Lakehouse

# 4. Configure dbt
cp dbt/profiles.yml.example ~/.dbt/profiles.yml
# Fill in your Warehouse SQL endpoint

# 5. Accept the challenge — no manual coding from here!
#    Read CHALLENGE.md, then open Claude Code (or your AI agent of choice)
#    and prompt your way to a green dbt test run.

cd dbt && dbt run && dbt test
```

---

## Dataset

[Contoso Data Generator V2](https://github.com/sql-bi/Contoso-Data-Generator-V2-data/releases/tag/ready-to-use-data) — open sample retail dataset by SQLBI.
This project uses the `parquet-100k` release (~100,000 orders).

---

## Stack

| Component | Technology |
|---|---|
| Lakehouse (Bronze) | Microsoft Fabric Lakehouse (Delta) |
| Warehouse (Silver/Gold/Serving) | Microsoft Fabric Warehouse |
| Transformations | dbt + dbt-fabric adapter |
| Workspace setup | fab-cli |
| Ingestion | Fabric Notebook (PySpark) + Data Pipeline |

---

## License

MIT — use freely, share your results!
