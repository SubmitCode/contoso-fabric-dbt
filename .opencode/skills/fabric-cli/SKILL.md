---
name: fabric-cli
description: Manage Microsoft Fabric workspaces, items, and jobs using the open-source Fabric CLI tool (fab). Use this skill when the task involves fabric cli, fab commands, creating workspaces, deploying pipelines, or fabric resource management. For notebook authoring, ingestion patterns, and Livy limitations, see the fabric-notebook skill.
---

## Overview

This skill uses the [Microsoft Fabric CLI](https://github.com/microsoft/fabric-cli) (`fab`) to:
- Authenticate (interactive browser login, service principal, or managed identity)
- Navigate workspaces like a file system (`ls`, `cd`, `mkdir`)
- Deploy pipelines, semantic models, and other Fabric items
- Run jobs (pipelines)
- Copy files to/from OneLake
- Manage workspace access (ACLs)
- Automate via CI/CD (GitHub Actions, Azure Pipelines)

> For notebook deployment format requirements and ingestion patterns, see the **fabric-notebook** skill.

---

## Installation

### Requirements
- Python 3.10, 3.11, 3.12 or 3.13
- `python` in your `PATH`

### Install
```bash
pip install ms-fabric-cli
```

### Upgrade
```bash
pip install --upgrade ms-fabric-cli
```

### Verify
```bash
fab --version
```

> **Note:** If another package named `fab` exists on your system (e.g. the `fabric` task runner),
> the wrong binary may be invoked. If `fab --version` shows the wrong tool, invoke ms-fabric-cli
> directly: `python3 -c "from fabric_cli.main import main; import sys; sys.argv=['fab']+sys.argv[1:]; main()"`

---

## Authentication

### Auth Check Protocol

Before running any `fab` command, check auth status:

```bash
fab auth status
```

- If `Logged In: True` → proceed normally
- If `Logged In: False` → run the login command (see below)

> **Note:** If your environment requires a proxy, load your proxy environment variables before running any `fab` command.

### User Login (Interactive)

```bash
fab auth login
```

When prompted, select **"Interactive with a web browser"**. A browser window will open for authentication.

> **Headless environments:** `fab auth login` opens a browser popup — there is no device code flow.
> In headless or CI environments, use a service principal or supply tokens via environment variables instead.

### Service Principal Login

```bash
# With client secret
fab auth login -u <client_id> -p <client_secret> --tenant <tenant_id>

# With certificate
fab auth login -u <client_id> --certificate /path/to/cert.pem --tenant <tenant_id>
```

### Managed Identity Login

```bash
# System-assigned
fab auth login --identity

# User-assigned
fab auth login --identity -u <client_id>
```

### Environment Variable Auth (CI/headless)

```bash
export FAB_TENANT_ID=<tenant_id>
export FAB_SPN_CLIENT_ID=<client_id>
export FAB_SPN_CLIENT_SECRET=<client_secret>
# fab commands now authenticate automatically
```

Or supply pre-acquired tokens directly:
```bash
export FAB_TOKEN=<fabric_access_token>
export FAB_TOKEN_ONELAKE=<onelake_access_token>
export FAB_TOKEN_AZURE=<azure_access_token>
```

### Auth Commands

| Command | Description |
|---------|-------------|
| `fab auth login` | Log in to Fabric CLI |
| `fab auth logout` | Log out of current session |
| `fab auth status` | Show authentication status |

---

## Common Commands

### File System Navigation

Navigate Fabric like a file system (Unix or Windows style):

```bash
# List all workspaces
fab ls

# List items in a workspace
fab ls "Sales Analytics.Workspace"

# Change directory
fab cd MyWorkspace.Workspace
```

### Configuration

```bash
# Set default capacity
fab config set default_capacity <capacity_name>

# View current config
fab config list
```

### Workspaces

```bash
# Create workspace
fab mkdir <WorkspaceName>.Workspace

# List workspaces
fab ls

# Get workspace details
fab ls <WorkspaceName>.Workspace

# Delete workspace
fab rmdir <WorkspaceName>.Workspace
```

### Access Control (ACLs)

```bash
# Add group/user to workspace
# -I = Object ID (group/user/service principal)
# -R = Role (Admin, Member, Contributor, Viewer)

# Add a group as Admin
fab acl set <WorkspaceName>.Workspace -I <group-object-id> -R Admin

# Add service principal as Admin
fab acl set <WorkspaceName>.Workspace -I <sp-object-id> -R Admin

# Add user as Contributor
fab acl set <WorkspaceName>.Workspace -I <user-object-id> -R Contributor

# List current ACLs
fab acl list <WorkspaceName>.Workspace
```

### Upload Items (import)

Import an item (create or modify).

> **Note:** When importing, the item definition is imported without its sensitivity label.

```bash
fab import <path> -i <input_path> [--format <format>] [-f]
```

**Parameters:**
- `<path>`: Destination path in Fabric
- `-i, --input <input_path>`: Local input path
- `--format <format>`: Format of item definition (optional, see below)
- `-f, --force`: Force import without confirmation

**Supported Formats:**
| Item Type | Formats |
|-----------|---------|
| Semantic Model | `TMDL`, `TMSL` |
| Spark Job Definition | `SparkJobDefinitionV1`, `SparkJobDefinitionV2` |

> For notebook import format requirements (`.ipynb` source field format, directory structure),
> see the **fabric-notebook** skill.

**Examples:**
```bash
# Import pipeline
fab import MyWorkspace.Workspace/MyPipeline.DataPipeline -i /path/to/MyPipeline.DataPipeline -f

# Import semantic model with TMDL format
fab import MyWorkspace.Workspace/MyModel.SemanticModel -i /path/to/model --format TMDL -f
```

### Download Items (export)

```bash
fab export <WorkspaceName>.Workspace/<ItemName>.<Type> -o <local-path>
```

### Copy Files to/from OneLake

```bash
# Upload a local file to lakehouse
fab cp ./local/data.csv MyWorkspace.Workspace/MyLakehouse.Lakehouse/Files/data.csv

# Download from OneLake
fab cp MyWorkspace.Workspace/MyLakehouse.Lakehouse/Files/data.csv ./local/
```

### Run Jobs

```bash
# Run a pipeline (synchronous - waits for completion)
fab job run MyWorkspace.Workspace/MyPipeline.DataPipeline

# Run pipeline with parameters
fab job run MyWorkspace.Workspace/MyPipeline.DataPipeline --params key1:type=value1,key2:type=value2

# Example with typed parameters
fab job run MyWorkspace.Workspace/DP_Load.DataPipeline --params bu_id:int=7,country:string=AT,days_back:int=30
```

**Note:** Use `fab job run` (not `fab run`) — the command is under the `job` subcommand.

> To run a notebook job, see the **fabric-notebook** skill.

### Job Status

```bash
# Get job status
fab job status <WorkspaceName>.Workspace/<ItemName>.<Type> --run-id <run-id>

# List recent job runs
fab job list <WorkspaceName>.Workspace/<ItemName>.<Type>
```

---

## Item Types

| Extension | Type |
|-----------|------|
| `.Workspace` | Workspace |
| `.Notebook` | Notebook |
| `.DataPipeline` | Data Pipeline |
| `.Lakehouse` | Lakehouse |
| `.Warehouse` | Warehouse |
| `.SemanticModel` | Semantic Model (Dataset) |
| `.Report` | Power BI Report |
| `.Dataflow` | Dataflow Gen2 |
| `.Environment` | Spark Environment |

---

## CI/CD Integration

### GitHub Actions Example

```yaml
- name: Deploy to Fabric
  run: |
    pip install ms-fabric-cli
    fab auth login -u ${{ secrets.CLIENT_ID }} -p ${{ secrets.CLIENT_SECRET }} --tenant ${{ secrets.TENANT_ID }}
    fab import Production.Workspace/Data.Lakehouse -i ./artifacts/DataToImport.Lakehouse
```

### Azure Pipelines Example

```yaml
- script: |
    pip install ms-fabric-cli
    fab auth login -u $(CLIENT_ID) -p $(CLIENT_SECRET) --tenant $(TENANT_ID)
    fab job run ETL.Workspace/DailyRefresh.DataPipeline
  displayName: 'Run Fabric pipeline'
```

---

## Example Workflows

### Provision a New Workspace with Resources

```bash
fab config set default_capacity <capacity_name> && \
fab mkdir MyProject.Workspace && \
fab acl set MyProject.Workspace -I <dev-group-id> -R Admin
```

### Deploy a Feature Branch Workspace

```bash
fab config set default_capacity <capacity_name> && \
fab mkdir Feature_MyFeature.Workspace && \
fab acl set Feature_MyFeature.Workspace -I <dev-group-id> -R Admin && \
fab import Feature_MyFeature.Workspace/DP_Main.DataPipeline -i ./workspace/DP_Main.DataPipeline -f && \
fab job run Feature_MyFeature.Workspace/DP_Main.DataPipeline
```

### Run Pipeline with Multiple Parameter Sets

```bash
fab job run MyWorkspace.Workspace/DP_Load.DataPipeline --params bu_id:int=7,country:string=AT && \
fab job run MyWorkspace.Workspace/DP_Load.DataPipeline --params bu_id:int=4,country:string=CH && \
fab job run MyWorkspace.Workspace/DP_Load.DataPipeline --params bu_id:int=3,country:string=LI
```

---

## Troubleshooting

### Authentication Issues
```bash
# Clear cached credentials and re-login
fab auth logout
fab auth login
```

### Wrong `fab` binary invoked
**Problem:** `fab` resolves to the `fabric` task runner (a different Python package), not ms-fabric-cli.
**Fix:** Use the full Python invocation or ensure ms-fabric-cli's entry point is first on `PATH`:
```bash
python3 -c "from fabric_cli.main import main; import sys; sys.argv=['fab']+sys.argv[1:]; main()" auth status
```

### Item Not Found
- Ensure workspace name includes `.Workspace` suffix
- Check item type suffix matches (`.DataPipeline`, `.SemanticModel`, etc.)

### Permission Denied
- Verify you have Admin or Contributor role on the workspace
- Check service principal has correct permissions

---

## References

- [Fabric CLI GitHub](https://github.com/microsoft/fabric-cli)
- [Fabric REST API](https://learn.microsoft.com/en-us/rest/api/fabric/)
- [Report an issue](https://github.com/microsoft/fabric-cli/issues)
- [Request a feature](https://github.com/microsoft/fabric-cli/discussions)
