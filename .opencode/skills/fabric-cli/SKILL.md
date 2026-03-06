---
name: fabric-cli
description: Manage Microsoft Fabric workspaces, items, and jobs using the open-source Fabric CLI tool (fab). Use this skill when the task involves fabric cli, fab commands, creating workspaces, uploading notebooks, running pipelines, or fabric deployments.
---

## Overview

This skill uses the [Microsoft Fabric CLI](https://github.com/microsoft/fabric-cli) (`fab`) to:
- Authenticate (interactive browser login, service principal, or managed identity)
- Navigate workspaces like a file system (`ls`, `cd`, `mkdir`)
- Upload notebooks, pipelines, and other items
- Run jobs (notebooks, pipelines)
- Copy files to/from OneLake
- Manage workspace access (ACLs)
- Automate via CI/CD (GitHub Actions, Azure Pipelines)

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
| Notebook | `.ipynb`, `.py` |
| Semantic Model | `TMDL`, `TMSL` |
| Spark Job Definition | `SparkJobDefinitionV1`, `SparkJobDefinitionV2` |

**Examples:**
```bash
# Import notebook to workspace
fab import MyWorkspace.Workspace -i /path/to/MyNotebook.Notebook

# Import notebook with force overwrite
fab import MyWorkspace.Workspace/MyNotebook.Notebook -i /path/to/MyNotebook.Notebook -f

# Import .ipynb file as notebook
fab import MyWorkspace.Workspace/MyNotebook.Notebook -i /path/to/notebook.ipynb --format .ipynb -f

# Import Python file as notebook
fab import MyWorkspace.Workspace/MyNotebook.Notebook -i /path/to/script.py --format .py -f

# Import pipeline
fab import MyWorkspace.Workspace/MyPipeline.DataPipeline -i /path/to/MyPipeline.DataPipeline -f

# Import semantic model with TMDL format
fab import MyWorkspace.Workspace/MyModel.SemanticModel -i /path/to/model --format TMDL -f
```

### Download Items (export)

```bash
fab export <WorkspaceName>.Workspace/<ItemName>.Notebook -o <local-path>
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

# Start a notebook (asynchronous)
fab job start MyWorkspace.Workspace/MyNotebook.Notebook

# Run pipeline with parameters
fab job run MyWorkspace.Workspace/MyPipeline.DataPipeline --params key1:type=value1,key2:type=value2

# Example with typed parameters
fab job run MyWorkspace.Workspace/DP_Load.DataPipeline --params bu_id:int=7,country:string=AT,days_back:int=30
```

**Note:** Use `fab job run` (not `fab run`) — the command is under the `job` subcommand.

### Job Status

```bash
# Get job status
fab job status <WorkspaceName>.Workspace/<ItemName>.Notebook --run-id <run-id>

# List recent job runs
fab job list <WorkspaceName>.Workspace/<ItemName>.Notebook
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

### Deploy a Feature Branch Workspace

```bash
fab config set default_capacity <capacity_name> && \
fab mkdir Feature_MyFeature.Workspace && \
fab acl set Feature_MyFeature.Workspace -I <dev-group-id> -R Admin && \
fab import Feature_MyFeature.Workspace/01_Setup.Notebook -i ./workspace/01_Setup.Notebook -f && \
fab import Feature_MyFeature.Workspace/02_Load.Notebook -i ./workspace/02_Load.Notebook -f && \
fab import Feature_MyFeature.Workspace/DP_Main.DataPipeline -i ./workspace/DP_Main.DataPipeline -f && \
fab job run Feature_MyFeature.Workspace/01_Setup.Notebook
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

### Item Not Found
- Ensure workspace name includes `.Workspace` suffix
- Check item type suffix matches (`.Notebook`, `.DataPipeline`, etc.)

### Permission Denied
- Verify you have Admin or Contributor role on the workspace
- Check service principal has correct permissions

### Notebook Import Fails with "InvalidNotebookContent"

**Problem:** Uploading `.ipynb` files fails with error about converting to `List[System.String]`.

**Cause:** Fabric requires the `source` field in each cell to be a **list of strings** (one per line), not a single string.

```json
// WRONG - source as single string
"source": "line1\nline2\nline3"

// CORRECT - source as list of strings
"source": ["line1\n", "line2\n", "line3"]
```

**Fix:** Convert the notebook before importing:
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

**Import structure:** Place the fixed `.ipynb` file in a directory:
```
my_notebook_import/
└── notebook-content.ipynb
```

Then import:
```bash
fab import "MyWorkspace.Workspace/MyNotebook.Notebook" -i ./my_notebook_import --format .ipynb -f
```

---

## References

- [Fabric CLI GitHub](https://github.com/microsoft/fabric-cli)
- [Fabric REST API](https://learn.microsoft.com/en-us/rest/api/fabric/)
- [Report an issue](https://github.com/microsoft/fabric-cli/issues)
- [Request a feature](https://github.com/microsoft/fabric-cli/discussions)
