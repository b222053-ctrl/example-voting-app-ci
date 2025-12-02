# Example Voting App - CI/CD Demo

A demo multi-language microservice application showcasing Azure DevOps CI/CD pipelines with Azure Container Registry.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure DevOps Pipelines                    │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │  Voting    │  │  Results   │  │  Worker    │            │
│  │  Pipeline  │  │  Pipeline  │  │  Pipeline  │            │
│  └──────┬─────┘  └──────┬─────┘  └──────┬─────┘            │
│         │                │                │                  │
│         └────────────────┼────────────────┘                  │
│                          ▼                                   │
│              Azure Container Registry (ACR)                  │
└─────────────────────────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
    ┌─────────┐     ┌─────────┐     ┌─────────┐
    │ Voting  │     │ Results │     │ Worker  │
    │ Python  │     │ Node.js │     │  .NET   │
    │  :5000  │     │  :8080  │     │  :5001  │
    └─────────┘     └─────────┘     └─────────┘
```

## Services

- **Voting** (Python/Flask): Accepts votes for options "a" or "b"
- **Results** (Node.js/Express): Displays service status and version
- **Worker** (.NET/ASP.NET): Background processing service

## Quick Start - Local Development

### Prerequisites
- Docker and Docker Compose
- Git

### Run Locally

```bash
# Clone the repository
git clone <repository-url>
cd example-voting-app-ci

# Start all services
docker-compose up --build

# Access services:
# Voting:  http://localhost:5000
# Results: http://localhost:8080
# Worker:  http://localhost:5001
```

### Test the services

```bash
# Check voting service health
curl http://localhost:5000/health

# Submit a vote
curl -X POST http://localhost:5000/vote -H "Content-Type: application/json" -d '{"option": "a"}'

# Check vote results
curl http://localhost:5000/results

# Check results service
curl http://localhost:8080

# Check worker service
curl http://localhost:5001/health
```

## Azure DevOps CI/CD Setup

### Step 1: Set Up Azure Container Registry (ACR)

1. Update placeholders in `infra/acr-setup.sh`:
   - `<ACR_NAME>`: Your ACR name (must be globally unique)
   - `<RESOURCE_GROUP>`: Azure resource group name
   - `<SUBSCRIPTION_ID>`: Your Azure subscription ID
   - `<SERVICE_PRINCIPAL_NAME>`: Service principal name

2. Run the setup script:
```bash
chmod +x infra/acr-setup.sh
./infra/acr-setup.sh
```

3. Save the service principal credentials output (appId, password, tenant)

### Step 2: Create Azure DevOps Service Connection

1. In Azure DevOps, go to **Project Settings** > **Service Connections**
2. Click **New service connection** > **Docker Registry**
3. Select **Azure Container Registry**
4. Choose **Service Principal**
5. Fill in details from step 1:
   - Docker Registry: `<ACR_NAME>.azurecr.io`
   - Service Principal ID: appId from script output
   - Service Principal Key: password from script output
   - Tenant ID: tenant from script output
6. Name the connection (e.g., "ACR-Connection")
7. Click **Verify and save**

### Step 3: Set Up Self-Hosted Agent (Optional)

If using a self-hosted agent pool:

1. Create an Agent Pool in Azure DevOps:
   - Go to **Organization Settings** > **Agent pools** > **Add pool**
   - Name it (e.g., "AzureAgent")

2. Generate a Personal Access Token (PAT):
   - Click your profile > **Personal access tokens** > **New Token**
   - Scope: **Agent Pools (read, manage)**
   - Copy the token

3. Update placeholders in `agent/setup-selfhosted-agent.sh`:
   - `<ORG>`: Your Azure DevOps organization
   - `<PAT>`: Personal Access Token from step 2
   - `<POOL_NAME>`: Agent pool name (e.g., "AzureAgent")

4. Run on your Linux VM:
```bash
chmod +x agent/setup-selfhosted-agent.sh
sudo ./agent/setup-selfhosted-agent.sh
```

### Step 4: Update Pipeline Files

Update the following in `azure-pipelines/*.yml` files:

1. **Pool name**: If using self-hosted agent, leave as `name: AzureAgent`. If using Microsoft-hosted, change to:
   ```yaml
   pool:
     vmImage: 'ubuntu-latest'
   ```

2. **Service Connection**: Replace `<ACR_SERVICE_CONNECTION>` with your service connection name from Step 2

### Step 5: Create Pipelines in Azure DevOps

1. Go to **Pipelines** > **New Pipeline**
2. Select **Azure Repos Git** (or your source)
3. Select your repository
4. Choose **Existing Azure Pipelines YAML file**
5. Select path: `/azure-pipelines/azure-pipelines-voting.yml`
6. Click **Run**
7. Repeat for `azure-pipelines-results.yml` and `azure-pipelines-worker.yml`

### Step 6: Verify Images in ACR

After pipelines run successfully:

```bash
# Login to ACR
az acr login --name <ACR_NAME>

# List repositories
az acr repository list --name <ACR_NAME> --output table

# List tags for a repository
az acr repository show-tags --name <ACR_NAME> --repository voting --output table
```

## Configuration Placeholders

Replace these placeholders before using:

| Placeholder | Description | Example |
|------------|-------------|---------|
| `<ORG>` | Azure DevOps organization | `mycompany` |
| `<PROJECT>` | Azure DevOps project | `voting-app` |
| `<PAT>` | Personal Access Token | `xxxxxxxxxxxxxx` |
| `<ACR_NAME>` | Azure Container Registry name | `mycompanyacr` |
| `<RESOURCE_GROUP>` | Azure resource group | `voting-app-rg` |
| `<SUBSCRIPTION_ID>` | Azure subscription ID | `00000000-0000-0000-0000-000000000000` |
| `<ACR_SERVICE_CONNECTION>` | Service connection name | `ACR-Connection` |
| `<SERVICE_PRINCIPAL_NAME>` | Service principal name | `acr-sp` |
| `<POOL_NAME>` | Agent pool name | `AzureAgent` |

## Troubleshooting

### Docker Permission Denied

If you get "permission denied" when running Docker commands:

```bash
# Add your user to the docker group
sudo usermod -aG docker $USER

# Log out and log back in, or run:
newgrp docker

# Verify
docker ps
```

### Pipeline Fails: "Service connection not found"

- Verify the service connection name in pipeline YAML matches the one created in Azure DevOps
- Check that the service connection has permissions to the ACR

### Self-Hosted Agent Not Appearing

```bash
# Check agent service status
sudo systemctl status vsts.agent.*

# View agent logs
cd /home/azagent/myagent
cat _diag/*.log

# Restart agent
sudo ./svc.sh stop
sudo ./svc.sh start
```

### ACR Login Fails

```bash
# Ensure you're logged into Azure
az login

# Set the correct subscription
az account set --subscription <SUBSCRIPTION_ID>

# Try logging in again
az acr login --name <ACR_NAME>
```

### Build Fails: "Cannot connect to Docker daemon"

On the agent machine:
```bash
# Check Docker is running
sudo systemctl status docker

# Start Docker if needed
sudo systemctl start docker

# Ensure agent user can access Docker
sudo usermod -aG docker azagent
```

## Pipeline Triggers

Pipelines are configured with path-based triggers:

- **Voting Pipeline**: Triggers on changes to `voting/**`
- **Results Pipeline**: Triggers on changes to `results/**`
- **Worker Pipeline**: Triggers on changes to `worker/**`

To manually run a pipeline:
1. Go to **Pipelines** in Azure DevOps
2. Select the pipeline
3. Click **Run pipeline**
4. Select the branch
5. Click **Run**

## Development

### Project Structure

```
.
├── azure-pipelines/       # Azure DevOps pipeline definitions
├── infra/                 # Infrastructure setup scripts
├── agent/                 # Agent setup scripts
├── results/               # Node.js results service
├── voting/                # Python voting service
├── worker/                # .NET worker service
├── docker-compose.yml     # Local development
└── README.md
```

### Adding New Services

1. Create a new directory for your service
2. Add Dockerfile and application code
3. Add service to `docker-compose.yml`
4. Create a new pipeline YAML in `azure-pipelines/`
5. Create the pipeline in Azure DevOps

## License

MIT License - see LICENSE file for details