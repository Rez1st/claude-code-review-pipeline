// Key Vault — stores all secrets (Anthropic key, Service Bus connection string)
param name string
param location string
param tags object

@secure()
param anthropicApiKey string

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: { family: 'A', name: 'standard' }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true   // use RBAC, not access policies
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
  }
}

resource anthropicSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'AnthropicApiKey'
  properties: {
    value: anthropicApiKey
  }
}

output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
output anthropicKeySecretUri string = anthropicSecret.properties.secretUri
