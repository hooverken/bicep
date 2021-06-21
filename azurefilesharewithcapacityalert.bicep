// azurefilesharewithcapacityalert.bicep

// creates an azure files share in the specified storage account and creates an alert for then
// that storage acocunt reaches the specified threshold

param storageAccountName string = 'kenstgtesting1'
param fileShareName string = 'fileshare2'
param sizeInGigabytes int = 50
param alertThreshold int = 40
param emailAddressToNotify string = 'ken.hoover@microsoft.com'

var windowSizeEvery1Hour = 'PT1H'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
}

resource newFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-04-01' = {
  name: '${storageAccount.name}/default/${fileShareName}'
  properties: {
    shareQuota: sizeInGigabytes
  }
}

resource actionGroup 'microsoft.insights/actionGroups@2019-06-01' = {
  name: '${fileShareName}-actionGroup'
  location: 'global'
  properties: {
    groupShortName: 'kentoso-ag'
    enabled: true
    emailReceivers: [
      {
        name: 'Ken Hoover (MSFT)'
        emailAddress: emailAddressToNotify
        useCommonAlertSchema: true
      }
    ]
  }
}

resource thresholdAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${fileShareName}-usagethresholdalert'
  location: 'global'
  properties: {
    description: 'Alert when usage levels hit the threshold'
    severity: 0
    enabled: true
    evaluationFrequency: 'PT15M'
    targetResourceType: newFileShare.type
    targetResourceRegion: resourceGroup().location
    windowSize: 'PT1H'
    scopes: [
      newFileShare.id
    ]
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          metricName: 'CapacityThreshold'
          timeAggregation: 'Average'
          name: 'capacityThreshold'
          operator: 'GreaterThan'
          threshold: alertThreshold
        }
      ]
    }
    actions: [
      {
        actionGroupId:actionGroup.id
      }
    ]
  }
}
