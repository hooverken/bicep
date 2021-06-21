// Creates a MG in the current tenant

targetScope = 'tenant'

var parentMGName = 'KentosoManagementGroup' // parent MG for the new one we are creating

resource parentMG 'Microsoft.Management/managementGroups@2020-05-01' existing = {
  name: '${parentMGName}'
}

resource newMG 'Microsoft.Management/managementGroups@2020-05-01' = {
  name: 'myTestManagementGroup'
  properties: {
    displayName: 'Test Management Group with Bicep'
    details: {
      parent: {
        id: parentMG.id
      }
    }
  }
}

output newManagementGroupId string = newMG.id
