// Azure Static Web Apps — React frontend (free tier, global CDN)
param name string
param location string
param tags object
param apiUrl string

resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = {
  name: name
  location: location  // SWA has limited region availability — westeurope works
  tags: tags
  sku: { name: 'Free', tier: 'Free' }
  properties: {
    // GitHub integration is configured post-deploy via the Azure Portal
    // or by passing repositoryUrl + branch + buildProperties here
    buildProperties: {
      appLocation: 'src/Frontend'
      outputLocation: 'dist'
      appBuildCommand: 'npm run build'
    }
  }
}

// Pass API URL as an app setting so the React app can reach the backend
resource swaAppSettings 'Microsoft.Web/staticSites/config@2023-01-01' = {
  parent: staticWebApp
  name: 'appsettings'
  properties: {
    VITE_API_URL: apiUrl
  }
}

output staticWebAppUrl string = 'https://${staticWebApp.properties.defaultHostname}'
