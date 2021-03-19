// Deploys a Windows Server 2019 VM with Hybrid benefit enabled

// Parameters
param virtualMachineName string
param virtualMachineSize string

param virtualNetworkName string
param virtualNetworkResourceGroupName string
param subnetName string

param adminUsername string
param adminPassword string

// Variables
var subnetId = '${subscription().id}/resourceGroups/${virtualNetworkResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${virtualNetworkName}/subnets/${subnetName}'
var vmImagePublisher = 'MicrosoftWindowsDesktop'
var vmImageOffer = 'Windows-10'
var vmImageSku = '20H2-EVD'


// Building the VM and its components

// The Availability set for the VM.  Need to figure out how to create it if it doesn't exist.
// resource availabilitySet 'Microsoft.Compute/availabilitySets@2020-06-01' existing = {
//   name: availabilitySetName
// }

// NSG for the NIC
resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01'= {
  name: '${virtualMachineName}-NSG'
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'default-allow-RDP'
        properties: {
          priority: 1000
          direction:'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange:'*'
          protocol: 'Tcp'
          destinationAddressPrefix:'*'
          destinationPortRange: '3389'
          access:'Allow'
        }
      }
      {
        name: 'default-allow-winrm-5985'
        properties: {
          priority: 1100
          direction:'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange:'*'
          protocol: 'Tcp'
          destinationAddressPrefix:'*'
          destinationPortRange: '5985'
          access:'Allow'
        }
      }
    ]
  }
}

// define the NIC for the VM
resource networkInterface 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: '${virtualMachineName}-NIC'
  location: resourceGroup().location
  properties: {
    // enableAcceleratedNetworking: true
    networkSecurityGroup: {
      id: nsg.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id : subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}


// Build the VM itself
resource virtualMachine 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: virtualMachineName
  location: resourceGroup().location
  properties: {
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        timeZone: 'Eastern Standard Time'
        winRM: {
          listeners: [
            {
              protocol:'Http'
            }
          ]
        }
      }
    }
    licenseType: 'Windows_Server'
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      imageReference: {
        publisher: vmImagePublisher
        offer: vmImageOffer
        sku: vmImageSku
        version: 'latest'
      }
      osDisk: {
        name: '${virtualMachineName}-OSdisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
  }
}


// TODO:  Add AD domain join

output virtualMachineName string = virtualMachineName
output virtualMachineSize string = virtualMachineSize
output privateIpAddress string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress


/////////////////////////////////////////////////////

{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
      "artifactsLocation": {
          "defaultValue": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration.zip",
          "type": "String",
          "metadata": {
              "description": "The base URI where artifacts required by this template are located."
          }
      },
      "availabilityOption": {
          "defaultValue": "None",
          "allowedValues": [
              "None",
              "AvailabilitySet",
              "AvailabilityZone"
          ],
          "type": "String",
          "metadata": {
              "description": "The availability option for the VMs."
          }
      },
      "availabilitySetName": {
          "defaultValue": "",
          "type": "String",
          "metadata": {
              "description": "The name of avaiability set to be used when create the VMs."
          }
      },
      "availabilityZone": {
          "defaultValue": 1,
          "allowedValues": [
              1,
              2,
              3
          ],
          "type": "Int",
          "metadata": {
              "description": "The number of availability zone to be used when create the VMs."
          }
      },
      "vmImageVhdUri": {
          "type": "String",
          "metadata": {
              "description": "URI of the sysprepped image vhd file to be used to create the session host VMs. For example, https://rdsstorage.blob.core.windows.net/vhds/sessionhostimage.vhd"
          }
      },
      "storageAccountResourceGroupName": {
          "type": "String",
          "metadata": {
              "description": "The storage account containing the custom VHD."
          }
      },
      "vmGalleryImageOffer": {
          "defaultValue": "",
          "type": "String",
          "metadata": {
              "description": "(Required when vmImageType = Gallery) Gallery image Offer."
          }
      },
      "vmGalleryImagePublisher": {
          "defaultValue": "",
          "type": "String",
          "metadata": {
              "description": "(Required when vmImageType = Gallery) Gallery image Publisher."
          }
      },
      "vmGalleryImageSKU": {
          "defaultValue": "",
          "type": "String",
          "metadata": {
              "description": "(Required when vmImageType = Gallery) Gallery image SKU."
          }
      },
      "rdshPrefix": {
          "defaultValue": "[take(toLower(resourceGroup().name),10)]",
          "type": "String",
          "metadata": {
              "description": "This prefix will be used in combination with the VM number to create the VM name. This value includes the dash, so if using “rdsh” as the prefix, VMs would be named “rdsh-0”, “rdsh-1”, etc. You should use a unique prefix to reduce name collisions in Active Directory."
          }
      },
      "rdshNumberOfInstances": {
          "type": "Int",
          "metadata": {
              "description": "Number of session hosts that will be created and added to the hostpool."
          }
      },
      "rdshVMDiskType": {
          "allowedValues": [
              "Premium_LRS",
              "StandardSSD_LRS",
              "Standard_LRS"
          ],
          "type": "String",
          "metadata": {
              "description": "The VM disk type for the VM: HDD or SSD."
          }
      },
      "rdshVmSize": {
          "defaultValue": "Standard_A2",
          "type": "String",
          "metadata": {
              "description": "The size of the session host VMs."
          }
      },
      "enableAcceleratedNetworking": {
          "defaultValue": false,
          "type": "Bool",
          "metadata": {
              "description": "Enables Accelerated Networking feature, notice that VM size must support it, this is supported in most of general purpose and compute-optimized instances with 2 or more vCPUs, on instances that supports hyperthreading it is required minimum of 4 vCPUs."
          }
      },
      "administratorAccountUsername": {
          "type": "String",
          "metadata": {
              "description": "The username for the domain admin."
          }
      },
      "administratorAccountPassword": {
          "type": "SecureString",
          "metadata": {
              "description": "The password that corresponds to the existing domain username."
          }
      },
      "vmAdministratorAccountUsername": {
          "defaultValue": "",
          "type": "String",
          "metadata": {
              "description": "The virtual machine admin user name. The domain administrator username will be used if this parameter is not provided."
          }
      },
      "vmAdministratorAccountPassword": {
          "defaultValue": "",
          "type": "SecureString",
          "metadata": {
              "description": "The virtual machine admin password. The domain administrator password will be used if this parameter is not provided."
          }
      },
      "vhds": {
          "type": "String",
          "metadata": {
              "description": "The URL to store unmanaged disks."
          }
      },
      "subnet-id": {
          "type": "String",
          "metadata": {
              "description": "The unique id of the subnet for the nics."
          }
      },
      "rdshImageSourceId": {
          "defaultValue": "",
          "type": "String",
          "metadata": {
              "description": "Resource ID of the image."
          }
      },
      "location": {
          "defaultValue": "",
          "type": "String",
          "metadata": {
              "description": "Location for all resources to be created in."
          }
      },
      "createNetworkSecurityGroup": {
          "defaultValue": false,
          "type": "Bool",
          "metadata": {
              "description": "Whether to create a new network security group or use an existing one"
          }
      },
      "networkSecurityGroupId": {
          "defaultValue": "",
          "type": "String",
          "metadata": {
              "description": "The resource id of an existing network security group"
          }
      },
      "networkSecurityGroupRules": {
          "defaultValue": [],
          "type": "Array",
          "metadata": {
              "description": "The rules to be given to the new network security group"
          }
      },
      "networkInterfaceTags": {
          "defaultValue": {},
          "type": "Object",
          "metadata": {
              "description": "The tags to be assigned to the network interfaces"
          }
      },
      "networkSecurityGroupTags": {
          "defaultValue": {},
          "type": "Object",
          "metadata": {
              "description": "The tags to be assigned to the network security groups"
          }
      },
      "virtualMachineTags": {
          "defaultValue": {},
          "type": "Object",
          "metadata": {
              "description": "The tags to be assigned to the virtual machines"
          }
      },
      "imageTags": {
          "defaultValue": {},
          "type": "Object",
          "metadata": {
              "description": "The tags to be assigned to the images"
          }
      },
      "vmInitialNumber": {
          "defaultValue": 0,
          "type": "Int",
          "metadata": {
              "description": "VM name prefix initial number."
          }
      },
      "_guidValue": {
          "defaultValue": "[newGuid()]",
          "type": "String"
      },
      "hostpoolToken": {
          "type": "String",
          "metadata": {
              "description": "The token for adding VMs to the hostpool"
          }
      },
      "hostpoolName": {
          "type": "String",
          "metadata": {
              "description": "The name of the hostpool"
          }
      },
      "ouPath": {
          "defaultValue": "",
          "type": "String",
          "metadata": {
              "description": "OUPath for the domain join"
          }
      },
      "domain": {
          "defaultValue": "",
          "type": "String",
          "metadata": {
              "description": "Domain to join"
          }
      },
      "aadJoin": {
          "defaultValue": false,
          "type": "Bool",
          "metadata": {
              "description": "True if AAD Join, false if AD join"
          }
      },
      "intune": {
          "defaultValue": false,
          "type": "Bool",
          "metadata": {
              "description": "True if intune enrollment is selected.  False otherwise"
          }
      }
  },
  "variables": {
      "emptyArray": [],
      "domain": "[if(equals(parameters('domain'), ''), last(split(parameters('administratorAccountUsername'), '@')), parameters('domain'))]",
      "storageAccountType": "[parameters('rdshVMDiskType')]",
      "newNsgName": "[concat(parameters('rdshPrefix'), 'nsg-', parameters('_guidValue'))]",
      "nsgId": "[if(parameters('createNetworkSecurityGroup'), resourceId('Microsoft.Network/networkSecurityGroups', variables('newNsgName')), parameters('networkSecurityGroupId'))]",
      "isVMAdminAccountCredentialsProvided": "[and(not(equals(parameters('vmAdministratorAccountUsername'), '')), not(equals(parameters('vmAdministratorAccountPassword'), '')))]",
      "vmAdministratorUsername": "[if(variables('isVMAdminAccountCredentialsProvided'), parameters('vmAdministratorAccountUsername'), first(split(parameters('administratorAccountUsername'), '@')))]",
      "vmAdministratorPassword": "[if(variables('isVMAdminAccountCredentialsProvided'), parameters('vmAdministratorAccountPassword'), parameters('administratorAccountPassword'))]",
      "vmAvailabilitySetResourceId": {
          "id": "[resourceId('Microsoft.Compute/availabilitySets/', parameters('availabilitySetName'))]"
      }
  },
  "resources": [
      {
          "type": "Microsoft.Resources/deployments",
          "apiVersion": "2018-05-01",
          "name": "NSG-linkedTemplate",
          "properties": {
              "mode": "Incremental",
              "template": {
                  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
                  "contentVersion": "1.0.0.0",
                  "resources": [
                      {
                          "condition": "[parameters('createNetworkSecurityGroup')]",
                          "type": "Microsoft.Network/networkSecurityGroups",
                          "apiVersion": "2019-02-01",
                          "name": "[variables('newNsgName')]",
                          "location": "[parameters('location')]",
                          "tags": "[parameters('networkSecurityGroupTags')]",
                          "properties": {
                              "securityRules": "[parameters('networkSecurityGroupRules')]"
                          }
                      }
                  ]
              }
          }
      },
      {
          "type": "Microsoft.Network/networkInterfaces",
          "apiVersion": "2018-11-01",
          "name": "[concat(parameters('rdshPrefix'), add(copyindex(), parameters('vmInitialNumber')), '-nic')]",
          "location": "[parameters('location')]",
          "dependsOn": [
              "NSG-linkedTemplate"
          ],
          "tags": "[parameters('networkInterfaceTags')]",
          "properties": {
              "ipConfigurations": [
                  {
                      "name": "ipconfig",
                      "properties": {
                          "privateIPAllocationMethod": "Dynamic",
                          "subnet": {
                              "id": "[parameters('subnet-id')]"
                          }
                      }
                  }
              ],
              "enableAcceleratedNetworking": "[parameters('enableAcceleratedNetworking')]",
              "networkSecurityGroup": "[if(empty(parameters('networkSecurityGroupId')), json('null'), json(concat('{\"id\": \"', variables('nsgId'), '\"}')))]"
          },
          "copy": {
              "name": "rdsh-nic-loop",
              "count": "[parameters('rdshNumberOfInstances')]"
          }
      },
      {
          "type": "Microsoft.Compute/virtualMachines",
          "apiVersion": "2018-10-01",
          "name": "[concat(parameters('rdshPrefix'), add(copyindex(), parameters('vmInitialNumber')))]",
          "location": "[parameters('location')]",
          "dependsOn": [
              "[concat('Microsoft.Network/networkInterfaces/', parameters('rdshPrefix'), add(copyindex(), parameters('vmInitialNumber')), '-nic')]"
          ],
          "tags": "[parameters('virtualMachineTags')]",
          "zones": "[if(equals(parameters('availabilityOption'), 'AvailabilityZone'), array(parameters('availabilityZone')), variables('emptyArray'))]",
          "identity": {
              "type": "[if(parameters('aadJoin'), 'systemAssigned', 'none')]"
          },
          "properties": {
              "hardwareProfile": {
                  "vmSize": "[parameters('rdshVmSize')]"
              },
              "availabilitySet": "[if(equals(parameters('availabilityOption'), 'AvailabilitySet'), variables('vmAvailabilitySetResourceId'), json('null'))]",
              "osProfile": {
                  "computerName": "[concat(parameters('rdshPrefix'), add(copyindex(), parameters('vmInitialNumber')))]",
                  "adminUsername": "[variables('vmAdministratorUsername')]",
                  "adminPassword": "[variables('vmAdministratorPassword')]"
              },
              "storageProfile": {
                  "imageReference": {
                      "publisher": "[parameters('vmGalleryImagePublisher')]",
                      "offer": "[parameters('vmGalleryImageOffer')]",
                      "sku": "[parameters('vmGalleryImageSKU')]",
                      "version": "latest"
                  },
                  "osDisk": {
                      "createOption": "FromImage",
                      "managedDisk": {
                          "storageAccountType": "[variables('storageAccountType')]"
                      }
                  }
              },
              "networkProfile": {
                  "networkInterfaces": [
                      {
                          "id": "[resourceId('Microsoft.Network/networkInterfaces',concat(parameters('rdshPrefix'), add(copyindex(), parameters('vmInitialNumber')), '-nic'))]"
                      }
                  ]
              },
              "diagnosticsProfile": {
                  "bootDiagnostics": {
                      "enabled": false
                  }
              },
              "licenseType": "Windows_Client"
          },
          "copy": {
              "name": "rdsh-vm-loop",
              "count": "[parameters('rdshNumberOfInstances')]"
          }
      },
      {
          "type": "Microsoft.Compute/virtualMachines/extensions",
          "apiVersion": "2018-10-01",
          "name": "[concat(parameters('rdshPrefix'), add(copyindex(), parameters('vmInitialNumber')), '/', 'dscextension')]",
          "location": "[parameters('location')]",
          "dependsOn": [
              "rdsh-vm-loop"
          ],
          "properties": {
              "publisher": "Microsoft.Powershell",
              "type": "DSC",
              "typeHandlerVersion": "2.73",
              "autoUpgradeMinorVersion": true,
              "settings": {
                  "modulesUrl": "[parameters('artifactsLocation')]",
                  "configurationFunction": "Configuration.ps1\\AddSessionHost",
                  "properties": {
                      "hostPoolName": "[parameters('hostpoolName')]",
                      "registrationInfoToken": "[parameters('hostpoolToken')]",
                      "aadJoin": "[parameters('aadJoin')]"
                  }
              }
          },
          "copy": {
              "name": "rdsh-dsc-loop",
              "count": "[parameters('rdshNumberOfInstances')]"
          }
      },
      {
          "type": "Microsoft.Compute/virtualMachines/extensions",
          "apiVersion": "2018-10-01",
          "name": "[concat(parameters('rdshPrefix'), add(copyindex(), parameters('vmInitialNumber')), '/', 'AADLoginForWindows')]",
          "location": "[parameters('location')]",
          "dependsOn": [
              "rdsh-dsc-loop"
          ],
          "properties": {
              "publisher": "Microsoft.Azure.ActiveDirectory",
              "type": "AADLoginForWindows",
              "typeHandlerVersion": "1.0",
              "autoUpgradeMinorVersion": true
          },
          "copy": {
              "name": "rdsh-aad-join-loop",
              "count": "[parameters('rdshNumberOfInstances')]"
          },
          "condition": "[and(parameters('aadJoin'),not(parameters('intune')))]"
      },
      {
          "type": "Microsoft.Compute/virtualMachines/extensions",
          "apiVersion": "2018-10-01",
          "name": "[concat(parameters('rdshPrefix'), add(copyindex(), parameters('vmInitialNumber')), '/', 'AADLoginForWindowsWithIntune')]",
          "location": "[parameters('location')]",
          "dependsOn": [
              "rdsh-dsc-loop"
          ],
          "properties": {
              "publisher": "Microsoft.Azure.ActiveDirectory",
              "type": "AADLoginForWindows",
              "typeHandlerVersion": "1.0",
              "autoUpgradeMinorVersion": true,
              "settings": {
                  "mdmId": "0000000a-0000-0000-c000-000000000000"
              }
          },
          "copy": {
              "name": "rdsh-aad-join-intune-loop",
              "count": "[parameters('rdshNumberOfInstances')]"
          },
          "condition": "[and(parameters('aadJoin'),parameters('intune'))]"
      },
      {
          "type": "Microsoft.Compute/virtualMachines/extensions",
          "apiVersion": "2018-10-01",
          "name": "[concat(parameters('rdshPrefix'), add(copyindex(), parameters('vmInitialNumber')), '/', 'joindomain')]",
          "location": "[parameters('location')]",
          "dependsOn": [
              "rdsh-dsc-loop"
          ],
          "properties": {
              "publisher": "Microsoft.Compute",
              "type": "JsonADDomainExtension",
              "typeHandlerVersion": "1.3",
              "autoUpgradeMinorVersion": true,
              "settings": {
                  "name": "[variables('domain')]",
                  "ouPath": "[parameters('ouPath')]",
                  "user": "[parameters('administratorAccountUsername')]",
                  "restart": "true",
                  "options": "3"
              },
              "protectedSettings": {
                  "password": "[parameters('administratorAccountPassword')]"
              }
          },
          "copy": {
              "name": "rdsh-domain-join-loop",
              "count": "[parameters('rdshNumberOfInstances')]"
          },
          "condition": "[not(parameters('aadJoin'))]"
      }
  ],
  "outputs": {}
}