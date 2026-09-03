@description('Prefix for the storage account name (must be globally unique, lowercase, no hyphens)')
param storageAccountPrefix string = 'portfoliosite'

@description('Azure region for all resources')
param location string = resourceGroup().location

var storageAccountName = take('${toLower(storageAccountPrefix)}${uniqueString(resourceGroup().id)}', 24)
var afdProfileName = '${storageAccountPrefix}-afd-profile'
var afdEndpointName = '${storageAccountPrefix}-afd-endpoint'
var originGroupName = 'storage-origin-group'
var originName = 'storage-origin'
var routeName = 'default-route'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: true
    minimumTlsVersion: 'TLS1_2'
  }
}

resource afdProfile 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: afdProfileName
  location: 'global'
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
}

resource afdEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  parent: afdProfile
  name: afdEndpointName
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource originGroup 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  parent: afdProfile
  name: originGroupName
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 100
    }
  }
}

resource origin 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  parent: originGroup
  name: originName
  properties: {
    hostName: replace(replace(storageAccount.properties.primaryEndpoints.web, 'https://', ''), '/', '')
    originHostHeader: replace(replace(storageAccount.properties.primaryEndpoints.web, 'https://', ''), '/', '')
    httpPort: 80
    httpsPort: 443
    priority: 1
    weight: 1000
  }
}

resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  parent: afdEndpoint
  name: routeName
  properties: {
    originGroup: {
      id: originGroup.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
  }
  dependsOn: [
    origin
  ]
}

output storageAccountName string = storageAccountName
output staticWebsiteUrl string = storageAccount.properties.primaryEndpoints.web
output frontDoorUrl string = 'https://${afdEndpoint.properties.hostName}'
