// App Service (ASP.NET Core API) + Azure SignalR Service
param appServicePlanName string
param appServiceName string
param signalRName string
param location string
param tags object
param keyVaultName string
param serviceBusConnectionStringSecretUri string

// App Service Plan (B1 — cheapest that supports always-on)
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: { name: 'B1', tier: 'Basic' }
  properties: { reserved: false } // Windows host for .NET 8
}

// Azure SignalR Service — managed backplane, required for multi-instance
resource signalR 'Microsoft.SignalRService/signalR@2023-02-01' = {
  name: signalRName
  location: location
  tags: tags
  sku: { name: 'Free_F1', capacity: 1 } // upgrade to Standard_S1 for prod
  properties: {
    features: [{ flag: 'ServiceMode', value: 'Default' }]
    cors: { allowedOrigins: ['*'] } // restrict to frontend URL in prod
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

// App Service
resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: appServiceName
  location: location
  tags: tags
  identity: { type: 'SystemAssigned' } // for Key Vault access via RBAC
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      netFrameworkVersion: 'v8.0'
      appSettings: [
        {
          name: 'Azure__SignalR__ConnectionString'
          value: signalR.listKeys().primaryConnectionString
        }
        {
          name: 'ServiceBus__ConnectionString'
          // Reference Key Vault secret directly via App Service KV reference
          value: '@Microsoft.KeyVault(SecretUri=${serviceBusConnectionStringSecretUri})'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
      ]
      webSocketsEnabled: true  // required for SignalR fallback
      alwaysOn: true
    }
  }
}

output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
output appServicePrincipalId string = appService.identity.principalId
