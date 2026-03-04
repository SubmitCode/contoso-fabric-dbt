#!/usr/bin/env bash
# =============================================================================
# 01_create_resources.sh
# Create Lakehouse and Warehouse in the Fabric workspace using fab-cli
# =============================================================================
# Prerequisites:
#   - 00_setup_workspace.sh has been run
#   - WORKSPACE_NAME matches the workspace created in step 00
# =============================================================================

set -euo pipefail

WORKSPACE_NAME="${WORKSPACE_NAME:-contoso-fabric-dbt}"
LAKEHOUSE_NAME="contoso_lakehouse"
WAREHOUSE_NAME="contoso_warehouse"

echo "Creating Lakehouse: $LAKEHOUSE_NAME"
# TODO: replace with actual fab-cli command once syntax is verified
# fab lakehouse create --workspace "$WORKSPACE_NAME" --name "$LAKEHOUSE_NAME"

echo ""
echo "Creating Warehouse: $WAREHOUSE_NAME"
# fab warehouse create --workspace "$WORKSPACE_NAME" --name "$WAREHOUSE_NAME"

echo ""
echo "Done."
echo ""
echo "Next steps:"
echo "  1. Upload notebooks/01_ingest_contoso.ipynb to your Lakehouse in the Fabric UI"
echo "  2. Run the notebook to load bronze Delta tables"
echo "  3. Find your Warehouse SQL connection string:"
echo "     Fabric UI → Warehouse → Settings → SQL connection string"
echo "  4. Copy dbt/profiles.yml.example → ~/.dbt/profiles.yml and fill in the connection string"
