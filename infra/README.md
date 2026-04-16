# Infrastructure — Azure

This folder contains all infrastructure-as-code (Bicep) and CI/CD (GitHub Actions) for deploying the claude-code-review-pipeline to Azure.

## What gets provisioned

| Resource | SKU (POC) | Purpose |
|---|---|---|
| Resource Group | — | Container for all resources |
| Azure App Service Plan | B1 | Hosts the ASP.NET Core API |
| Azure App Service | — | ASP.NET Core Web API + SignalR hub |
| Azure SignalR Service | Free | Managed SignalR backplane (multi-instance safe) |
| Azure Service Bus Namespace | Basic | Message queue (replaces local RabbitMQ) |
| Azure Service Bus Queue | — | `code-review-jobs` queue |
| Azure Container Apps Environment | Consumption | Hosts the .NET Worker Service |
| Azure Container App | — | .NET Worker Service (auto-scales with queue depth) |
| Azure Static Web Apps | Free | React frontend (global CDN, GitHub deploy) |
| Azure Key Vault | Standard | Stores Anthropic API key and connection strings |
| Azure Container Registry | Basic | Docker images for API + Worker |

## Files

- `main.bicep` — master Bicep template, orchestrates all modules
- `modules/api.bicep` — App Service + SignalR Service
- `modules/messaging.bicep` — Service Bus namespace + queue
- `modules/worker.bicep` — Container Apps environment + worker app
- `modules/frontend.bicep` — Static Web Apps
- `modules/keyvault.bicep` — Key Vault + secrets
- `parameters.dev.json` — parameter values for dev/POC deployment
- `.github/workflows/deploy.yml` — GitHub Actions CI/CD pipeline

## Deploy

### Prerequisites
- Azure CLI installed and logged in (`az login`)
- Azure subscription
- GitHub repo connected

### One-time setup

```bash
# Create resource group
az group create --name rg-claude-review-poc --location westeurope

# Deploy all infrastructure
az deployment group create \
  --resource-group rg-claude-review-poc \
  --template-file infra/main.bicep \
  --parameters @infra/parameters.dev.json \
  --parameters anthropicApiKey=<your-key>
```

### After deploy
GitHub Actions takes over on every push to `master`. See `.github/workflows/deploy.yml`.

## Cost estimate (POC)

| Service | Monthly cost |
|---|---|
| App Service B1 | ~€13 |
| SignalR Free tier | €0 |
| Service Bus Basic | ~€0.05 |
| Container Apps (consumption) | ~€1–3 depending on load |
| Static Web Apps Free | €0 |
| Key Vault Standard | ~€0.05 |
| Container Registry Basic | ~€5 |
| **Total** | **~€20–25/month** |

Upgrade to Standard tiers when moving beyond POC.
