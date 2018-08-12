    {
      "apiVersion": "[variables('apiVersionDefault')]",
      "copy": {
        "count": "[sub(variables('{{.Name}}Count'), variables('{{.Name}}Variables').{{.Name}}Offset)]",
        "name": "loop"
      },
      "dependsOn": [
{{if .IsCustomVNET}}
      "[variables('nsgID')]"
{{else}}
      "[variables('vnetID')]"
{{end}}
      ],
      "location": "[variables('location')]",
      "name": "[concat(variables('{{.Name}}Variables').{{.Name}}VMNamePrefix, 'nic-', copyIndex(variables('{{.Name}}Variables').{{.Name}}Offset))]",
      "properties": {
{{if .IsCustomVNET}}
	    "networkSecurityGroup": {
		    "id": "[variables('nsgID')]"
	    },
{{end}}
        "ipConfigurations": [
          {{range $seq := loop 1 .IPAddressCount}}
          {
            "name": "ipconfig{{$seq}}",
            "properties": {
              {{if eq $seq 1}}
              "primary": true,
              {{end}}
              "privateIPAllocationMethod": "Dynamic",
              "subnet": {
                "id": "[variables('{{$.Name}}Variables').{{$.Name}}VnetSubnetID]"
             }
            }
          }
          {{if lt $seq $.IPAddressCount}},{{end}}
          {{end}}
        ]
{{if not IsAzureCNI}}
        ,
        "enableIPForwarding": true
{{end}}
      },
      "type": "Microsoft.Network/networkInterfaces"
    },
{{if .IsManagedDisks}}
   {
      "location": "[variables('location')]",
      "name": "[variables('{{.Name}}AvailabilitySet')]",
      "apiVersion": "[variables('apiVersionStorageManagedDisks')]",
      "properties":
        {
            "platformFaultDomainCount": "2",
            "platformUpdateDomainCount": "3",
		        "managed" : "true"
        },

      "type": "Microsoft.Compute/availabilitySets"
    },
{{else if .IsStorageAccount}}
    {
      "apiVersion": "[variables('apiVersionStorage')]",
      "copy": {
        "count": "[variables('{{.Name}}Variables').{{.Name}}StorageAccountsCount]",
        "name": "loop"
      },
      {{if not IsHostedMaster}}
        {{if not IsPrivateCluster}}
          "dependsOn": [
            "[concat('Microsoft.Network/publicIPAddresses/', variables('masterPublicIPAddressName'))]"
          ],
        {{end}}
      {{end}}
      "kind": "Storage",
      "location": "[variables('location')]",
      "name": "[concat(variables('storageAccountPrefixes')[mod(add(copyIndex(),variables('{{.Name}}Variables').{{.Name}}StorageAccountOffset),variables('storageAccountPrefixesCount'))],variables('storageAccountPrefixes')[div(add(copyIndex(),variables('{{.Name}}Variables').{{.Name}}StorageAccountOffset),variables('storageAccountPrefixesCount'))],variables('{{.Name}}AccountName'))]",
      "properties": {
        "encryption": {
          "keySource": "Microsoft.Storage",
          "services": {
            "blob": {
              "enabled": true
            },
            "file": {
              "enabled": true
            }
          }
        },
        "supportsHttpsTrafficOnly": true
      },
      "sku": {
        "name": "[variables('vmSizesMap')[variables('{{.Name}}Variables').{{.Name}}VMSize].storageAccountType]"
      },
      "type": "Microsoft.Storage/storageAccounts"
    },
    {{if .HasDisks}}
    {
      "apiVersion": "[variables('apiVersionStorage')]",
      "copy": {
        "count": "[variables('{{.Name}}Variables').{{.Name}}StorageAccountsCount]",
        "name": "datadiskLoop"
      },
      {{if not IsHostedMaster}}
        {{if not IsPrivateCluster}}
          "dependsOn": [
            "[concat('Microsoft.Network/publicIPAddresses/', variables('masterPublicIPAddressName'))]"
          ],
        {{end}}
      {{end}}
      "kind": "Storage",
      "location": "[variables('location')]",
      "name": "[concat(variables('storageAccountPrefixes')[mod(add(copyIndex(variables('dataStorageAccountPrefixSeed')),variables('{{.Name}}Variables').{{.Name}}StorageAccountOffset),variables('storageAccountPrefixesCount'))],variables('storageAccountPrefixes')[div(add(copyIndex(variables('dataStorageAccountPrefixSeed')),variables('{{.Name}}Variables').{{.Name}}StorageAccountOffset),variables('storageAccountPrefixesCount'))],variables('{{.Name}}DataAccountName'))]",
      "properties": {
        "encryption": {
          "keySource": "Microsoft.Storage",
          "services": {
            "blob": {
              "enabled": true
            },
            "file": {
              "enabled": true
            }
          }
        },
        "supportsHttpsTrafficOnly": true
      },
      "sku": {
        "name": "[variables('vmSizesMap')[variables('{{.Name}}Variables').{{.Name}}VMSize].storageAccountType]"
      },
      "type": "Microsoft.Storage/storageAccounts"
    },
    {{end}}
    {
      "location": "[variables('location')]",
      "name": "[variables('{{.Name}}AvailabilitySet')]",
      "apiVersion": "[variables('apiVersionDefault')]",
      "properties": {},
      "type": "Microsoft.Compute/availabilitySets"
    },
{{end}}
    {
      {{if .IsManagedDisks}}
        "apiVersion": "[variables('apiVersionStorageManagedDisks')]",
      {{else}}
        "apiVersion": "[variables('apiVersionDefault')]",
      {{end}}
      "copy": {
        "count": "[sub(variables('{{.Name}}Count'), variables('{{.Name}}Variables').{{.Name}}Offset)]",
        "name": "vmLoopNode"
      },
      "dependsOn": [
{{if .IsStorageAccount}}
        "[concat('Microsoft.Storage/storageAccounts/',variables('storageAccountPrefixes')[mod(add(div(copyIndex(variables('{{.Name}}Variables').{{.Name}}Offset),variables('maxVMsPerStorageAccount')),variables('{{.Name}}Variables').{{.Name}}StorageAccountOffset),variables('storageAccountPrefixesCount'))],variables('storageAccountPrefixes')[div(add(div(copyIndex(variables('{{.Name}}Variables').{{.Name}}Offset),variables('maxVMsPerStorageAccount')),variables('{{.Name}}Variables').{{.Name}}StorageAccountOffset),variables('storageAccountPrefixesCount'))],variables('{{.Name}}AccountName'))]",
  {{if .HasDisks}}
        "[concat('Microsoft.Storage/storageAccounts/',variables('storageAccountPrefixes')[mod(add(add(div(copyIndex(variables('{{.Name}}Variables').{{.Name}}Offset),variables('maxVMsPerStorageAccount')),variables('{{.Name}}Variables').{{.Name}}StorageAccountOffset),variables('dataStorageAccountPrefixSeed')),variables('storageAccountPrefixesCount'))],variables('storageAccountPrefixes')[div(add(add(div(copyIndex(variables('{{.Name}}Variables').{{.Name}}Offset),variables('maxVMsPerStorageAccount')),variables('{{.Name}}Variables').{{.Name}}StorageAccountOffset),variables('dataStorageAccountPrefixSeed')),variables('storageAccountPrefixesCount'))],variables('{{.Name}}DataAccountName'))]",
  {{end}}
{{end}}
        "[concat('Microsoft.Network/networkInterfaces/', variables('{{.Name}}Variables').{{.Name}}VMNamePrefix, 'nic-', copyIndex(variables('{{.Name}}Variables').{{.Name}}Offset))]",
        "[concat('Microsoft.Compute/availabilitySets/', variables('{{.Name}}AvailabilitySet'))]"
      ],
      "tags":
      {
        "creationSource" : "[concat(variables('generatorCode'), '-', variables('{{.Name}}Variables').{{.Name}}VMNamePrefix, copyIndex(variables('{{.Name}}Variables').{{.Name}}Offset))]",
        "resourceNameSuffix" : "[variables('winResourceNamePrefix')]",
        "orchestrator" : "[variables('orchestratorNameVersionTag')]",
        "poolName" : "{{.Name}}"
      },
      "location": "[variables('location')]",
      "name": "[concat(variables('{{.Name}}Variables').{{.Name}}VMNamePrefix, copyIndex(variables('{{.Name}}Variables').{{.Name}}Offset))]",
      {{if UseManagedIdentity}}
      "identity": {
        "type": "systemAssigned"
      },
      {{end}}
      "properties": {
        "availabilitySet": {
          "id": "[resourceId('Microsoft.Compute/availabilitySets',variables('{{.Name}}AvailabilitySet'))]"
        },
        "hardwareProfile": {
          "vmSize": "[variables('{{.Name}}Variables').{{.Name}}VMSize]"
        },
        "networkProfile": {
          "networkInterfaces": [
            {
              "id": "[resourceId('Microsoft.Network/networkInterfaces',concat(variables('{{.Name}}Variables').{{.Name}}VMNamePrefix, 'nic-', copyIndex(variables('{{.Name}}Variables').{{.Name}}Offset)))]"
            }
          ]
        },
        "osProfile": {
          "computername": "[concat(variables('{{.Name}}Variables').{{.Name}}VMNamePrefix, copyIndex(variables('{{.Name}}Variables').{{.Name}}Offset))]",
          {{GetKubernetesWindowsAgentCustomData .}}
          "adminUsername": "[variables('windowsAdminUsername')]",
          "adminPassword": "[variables('windowsAdminPassword')]",
          "windowsConfiguration": {
            "enableAutomaticUpdates": false
          }
        },
        "storageProfile": {
          {{GetDataDisks .}}
          "imageReference": {
            "offer": "[variables('agentWindowsOffer')]",
            "publisher": "[variables('agentWindowsPublisher')]",
            "sku": "[variables('agentWindowsSku')]",
            "version": "[variables('agentWindowsVersion')]"
          },
          "osDisk": {
            "createOption": "FromImage"
            ,"caching": "ReadWrite"
{{if .IsStorageAccount}}
            ,"name": "[concat(variables('{{.Name}}Variables').{{.Name}}VMNamePrefix, copyIndex(variables('{{.Name}}Variables').{{.Name}}Offset),'-osdisk')]"
            ,"vhd": {
              "uri": "[concat(reference(concat('Microsoft.Storage/storageAccounts/',variables('storageAccountPrefixes')[mod(add(div(copyIndex(variables('{{.Name}}Variables').{{.Name}}Offset),variables('maxVMsPerStorageAccount')),variables('{{.Name}}Variables').{{.Name}}StorageAccountOffset),variables('storageAccountPrefixesCount'))],variables('storageAccountPrefixes')[div(add(div(copyIndex(variables('{{.Name}}Variables').{{.Name}}Offset),variables('maxVMsPerStorageAccount')),variables('{{.Name}}Variables').{{.Name}}StorageAccountOffset),variables('storageAccountPrefixesCount'))],variables('{{.Name}}AccountName')),variables('apiVersionStorage')).primaryEndpoints.blob,'osdisk/', variables('{{.Name}}Variables').{{.Name}}VMNamePrefix, copyIndex(variables('{{.Name}}Variables').{{.Name}}Offset), '-osdisk.vhd')]"
            }
{{end}}
{{if ne .OSDiskSizeGB 0}}
            ,"diskSizeGB": {{.OSDiskSizeGB}}
{{end}}
          }
        }
      },
      "type": "Microsoft.Compute/virtualMachines"
    },
    {{if UseManagedIdentity}}
    {
      "apiVersion": "2014-10-01-preview",
      "copy": {
         "count": "[variables('{{.Name}}Count')]",
         "name": "vmLoopNode"
       },
      "name": "[guid(concat('Microsoft.Compute/virtualMachines/', variables('{{.Name}}Variables').{{.Name}}VMNamePrefix, copyIndex(),'vmidentity'))]",
      "type": "Microsoft.Authorization/roleAssignments",
      "properties": {
        "roleDefinitionId": "[variables('readerRoleDefinitionId')]",
        "principalId": "[reference(concat('Microsoft.Compute/virtualMachines/', variables('{{.Name}}Variables').{{.Name}}VMNamePrefix, copyIndex()), '2017-03-30', 'Full').identity.principalId]"
      }
    },
      {
        "type": "Microsoft.Compute/virtualMachines/extensions",
        "name": "[concat(variables('{{.Name}}Variables').{{.Name}}VMNamePrefix, copyIndex(), '/ManagedIdentityExtension')]",
        "copy": {
          "count": "[variables('{{.Name}}Count')]",
          "name": "vmLoopNode"
        },
        "apiVersion": "2015-05-01-preview",
        "location": "[resourceGroup().location]",
        "dependsOn": [
          "[concat('Microsoft.Compute/virtualMachines/', variables('{{.Name}}Variables').{{.Name}}VMNamePrefix, copyIndex())]",
          "[concat('Microsoft.Authorization/roleAssignments/', guid(concat('Microsoft.Compute/virtualMachines/', variables('{{.Name}}Variables').{{.Name}}VMNamePrefix, copyIndex(), 'vmidentity')))]"
        ],
        "properties": {
          "publisher": "Microsoft.ManagedIdentity",
          "type": "ManagedIdentityExtensionForWindows",
          "typeHandlerVersion": "1.0",
          "autoUpgradeMinorVersion": true,
          "settings": {
            "port": 50343
          },
          "protectedSettings": {}
        }
      },
     {{end}}
    {
      "apiVersion": "[variables('apiVersionDefault')]",
      "copy": {
        "count": "[sub(variables('{{.Name}}Count'), variables('{{.Name}}Variables').{{.Name}}Offset)]",
        "name": "vmLoopNode"
      },
      "dependsOn": [
        {{if UseManagedIdentity}}
        "[concat('Microsoft.Compute/virtualMachines/', variables('{{.Name}}Variables').{{.Name}}VMNamePrefix, copyIndex(), '/extensions/ManagedIdentityExtension')]"
        {{else}}
        "[concat('Microsoft.Compute/virtualMachines/', variables('{{.Name}}Variables').{{.Name}}VMNamePrefix, copyIndex(variables('{{.Name}}Variables').{{.Name}}Offset))]"
        {{end}}
      ],
      "location": "[variables('location')]",
      "type": "Microsoft.Compute/virtualMachines/extensions",
      "name": "[concat(variables('{{.Name}}Variables').{{.Name}}VMNamePrefix, copyIndex(variables('{{.Name}}Variables').{{.Name}}Offset), '/cse')]",
      "properties": {
        "publisher": "Microsoft.Compute",
        "type": "CustomScriptExtension",
        "typeHandlerVersion": "1.8",
        "autoUpgradeMinorVersion": true,
        "settings": {},
        "protectedSettings": {
          "commandToExecute": "[concat('powershell.exe -ExecutionPolicy Unrestricted -command \"', '$arguments = ', variables('singleQuote'),'-MasterIP ',variables('kubernetesAPIServerIP'),' -KubeDnsServiceIp ',variables('kubeDnsServiceIp'),' -MasterFQDNPrefix ',variables('masterFqdnPrefix'),' -Location ',variables('location'),' -AgentKey ',variables('clientPrivateKey'),' -AzureHostname ',variables('{{.Name}}Variables').{{.Name}}VMNamePrefix,copyIndex(variables('{{.Name}}Variables').{{.Name}}Offset),variables('singleQuote'), ' ; ', variables('windowsCustomScriptSuffix'), '\" > %SYSTEMDRIVE%\\AzureData\\CustomDataSetupScript.log 2>&1')]"
        }
      }
    }