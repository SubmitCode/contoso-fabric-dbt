#!/usr/bin/env bash
# =============================================================================
# 00_setup_workspace.sh
# Create a Microsoft Fabric workspace using fab-cli
# =============================================================================
# Prerequisites:
#   - fab-cli installed and authenticated (fab auth login)
#   - WORKSPACE_NAME set below or passed as env variable
# =============================================================================

set -euo pipefail

WORKSPACE_NAME="${WORKSPACE_NAME:-contoso-fabric-dbt}"

echo "Creating Fabric workspace: $WORKSPACE_NAME"
# TODO: replace with actual fab-cli command once syntax is verified
# fab workspace create --name "$WORKSPACE_NAME"

echo ""
echo "Optional: add team members to the workspace"
# Uncomment and fill in to add users:
# fab workspace assign-user \
#   --workspace "$WORKSPACE_NAME" \
#   --email "user@example.com" \
#   --role "Member"

echo ""
echo "Done. Note your workspace ID for the next script."
echo "Find it in the Fabric UI or via: fab workspace list"
