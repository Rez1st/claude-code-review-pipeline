// Service Bus namespace + code-review-jobs queue
param namespaceName string
param location string
param tags object
param keyVaultName string

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: namespaceName
  location: location
  tags: tags
  sku: {
    name: 'Basic' // Upgrade to Standard for topics/subscriptions in prod
    tier: 'Basic'
  }
}

resource reviewQueue 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  parent: serviceBusNamespace
  name: 'code-review-jobs'
  properties: {
    maxDeliveryCount: 5           // retry up to 5x before dead-lettering
    lockDuration: 'PT5M'          // 5 min lock — enough for Claude to respond
    defaultMessageTimeToLive: 'PT1H'
    deadLetteringOnMessageExpiration: true
  }
}

resource deadLetterQueue 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  parent: serviceBusNamespace
  name: 'code-review-jobs-results'
  properties: {
    maxDeliveryCount: 3
    defaultMessageTimeToLive: 'P1D'
  }
}

// Root manage shared access key for connection string
resource rootManageKey 'Microsoft.ServiceBus/namespaces/authorizationRules@2022-10-01-preview' existing = {
  parent: serviceBusNamespace
  name: 'RootManageSharedAccessKey'
}

// Store connection string in Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource sbConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'ServiceBusConnectionString'
  properties: {
    value: serviceBusNamespace.listKeys('RootManageSharedAccessKey', '2022-10-01-preview').primaryConnectionString
  }
}

output namespaceName string = serviceBusNamespace.name
output connectionStringSecretUri string = sbConnectionStringSecret.properties.secretUri
