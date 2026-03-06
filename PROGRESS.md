# Contoso Fabric dbt — Progress Log

## Fabric Resources

| Resource | Name | ID |
|---|---|---|
| Workspace | contoso-challenge | `39475fe3-20a6-4f64-b7e5-9b45a536406b` |
| Capacity | fabricdatacoe | `5190c581-5cac-4f39-998b-c1e5614652bf` |
| Lakehouse | contoso_lakehouse | `e15fc533-c44a-42e8-9a58-c3ea59eeccf5` |
| Warehouse | contoso_warehouse | `3485906c-1613-4b7d-b20d-d1e493861334` |

## Completed Steps

- [x] Workspace `contoso-challenge` created (2026-03-05)
- [x] Lakehouse `contoso_lakehouse` created (2026-03-05)
- [x] Warehouse `contoso_warehouse` created (2026-03-05)

## Pending Steps

- [ ] Create Lakehouse `contoso_lakehouse`
- [ ] Create Warehouse `contoso_warehouse`
- [ ] Upload & run ingestion notebook → bronze Delta tables
- [ ] Configure dbt profiles.yml with Warehouse SQL endpoint
- [ ] Implement + run silver layer (dbt)
- [ ] Implement + run gold layer (dbt)
- [ ] Implement + run serving layer (dbt)
- [ ] All dbt tests green

## Notes

- fab-cli binary: `~/.local/bin/fab`
- Tenant: `d1ebceca-ef4e-45af-8bd0-bd89a76451c8`
- Auth account: `cfwi@nimbusplane.io`
- dbt profile name: `contoso_fabric_dbt`
- Warehouse SQL endpoint: `zlhoxuko56xulc6qxwe2ozcrza-4npuoongebse7n7ftnc2knsanm.datawarehouse.fabric.microsoft.com`
