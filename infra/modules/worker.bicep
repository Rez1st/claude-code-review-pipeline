// Container Apps — .NET Worker Service (queue consumer)
param environmentName string
param appName string
param location string
param tags object
param containerRegistryName string
param keyVaultName string
param serviceBusConnectionStringSecretUri string
param anthropicKeySecretUri string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
}

// Container Apps Environment (shared runtime for all container apps)
resource containerAppsEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: environmentName
  location: location
  tags: tags
  properties: {
    // No Log Analytics wired here for POC — add for production
  }
}

// Worker Container App
resource workerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: appName
  location: location
  tags: tags
  identity: { type: 'SystemAssigned' }
  properties: {
    managedEnvironmentId: containerAppsEnv.id
    configuration: {
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: 'system'
        }
      ]
      secrets: [
        {
          name: 'sb-connection-string'
          keyVaultUrl: serviceBusConnectionStringSecretUri
          identity: 'system'
        }
        {
          name: 'anthropic-api-key'
          keyVaultUrl: anthropicKeySecretUri
          identity: 'system'
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'worker'
          image: '${containerRegistry.properties.loginServer}/claude-review-worker:latest'
          resources: { cpu: json('0.5'), memory: '1Gi' }
          env: [
            { name: 'ServiceBus__ConnectionString', secretRef: 'sb-connection-string' }
            { name: 'Anthropic__ApiKey', secretRef: 'anthropic-api-key' }
            { name: 'ServiceBus__QueueName', value: 'code-review-jobs' }
            { name: 'DOTNET_ENVIRONMENT', value: 'Production' }
          ]
        }
      ]
      scale: {
        minReplicas: 0   // scale to zero when queue is empty
        maxReplicas: 10  // scale out under load
        rules: [
          {
            name: 'servicebus-queue-depth'
            custom: {
              type: 'azure-servicebus'
              metadata: {
                queueName: 'code-review-jobs'
                messageCount: '5' // scale up when >5 messages waiting
              }
              auth: [
                { secretRef: 'sb-connection-string', triggerParameter: 'connection' }
              ]
            }
          }
        ]
      }
    }
  }
}

output workerAppName string = workerApp.name
output workerPrincipalId string = workerApp.identity.principalId
