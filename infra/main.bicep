// claude-code-review-pipeline — main Bicep template
// Orchestrates all modules for a full Azure deployment

targetScope = 'resourceGroup'

@description('Environment name (dev, staging, prod)')
param environment string = 'dev'

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Anthropic API key — stored in Key Vault, never in plain config')
@secure()
param anthropicApiKey string

@description('Container registry login server (set after ACR is created)')
param containerRegistryName string = 'acrclaudereview${environment}'

var prefix = 'claude-review-${environment}'
var tags = {
  project: 'claude-code-review-pipeline'
  environment: environment
  managedBy: 'bicep'
}

// ── Key Vault ────────────────────────────────────────────────────────────────
module keyVault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    name: 'kv-${replace(prefix, '-', '')}' // KV names have char limits
    location: location
    tags: tags
    anthropicApiKey: anthropicApiKey
  }
}

// ── Messaging (Service Bus) ──────────────────────────────────────────────────
module messaging 'modules/messaging.bicep' = {
  name: 'messaging'
  params: {
    namespaceName: 'sb-${prefix}'
    location: location
    tags: tags
    keyVaultName: keyVault.outputs.keyVaultName
  }
}

// ── API + SignalR ────────────────────────────────────────────────────────────
module api 'modules/api.bicep' = {
  name: 'api'
  params: {
    appServicePlanName: 'asp-${prefix}'
    appServiceName: 'app-${prefix}'
    signalRName: 'sigr-${prefix}'
    location: location
    tags: tags
    keyVaultName: keyVault.outputs.keyVaultName
    serviceBusConnectionStringSecretUri: messaging.outputs.connectionStringSecretUri
  }
}

// ── Worker (Container Apps) ──────────────────────────────────────────────────
module worker 'modules/worker.bicep' = {
  name: 'worker'
  params: {
    environmentName: 'cae-${prefix}'
    appName: 'ca-worker-${prefix}'
    location: location
    tags: tags
    containerRegistryName: containerRegistryName
    keyVaultName: keyVault.outputs.keyVaultName
    serviceBusConnectionStringSecretUri: messaging.outputs.connectionStringSecretUri
    anthropicKeySecretUri: keyVault.outputs.anthropicKeySecretUri
  }
}

// ── Frontend (Static Web Apps) ───────────────────────────────────────────────
module frontend 'modules/frontend.bicep' = {
  name: 'frontend'
  params: {
    name: 'swa-${prefix}'
    location: location
    tags: tags
    apiUrl: api.outputs.appServiceUrl
  }
}

// ── Outputs ──────────────────────────────────────────────────────────────────
output apiUrl string = api.outputs.appServiceUrl
output frontendUrl string = frontend.outputs.staticWebAppUrl
output serviceBusNamespace string = messaging.outputs.namespaceName
output keyVaultName string = keyVault.outputs.keyVaultName
