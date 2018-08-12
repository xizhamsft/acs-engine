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
                {{if eq $.Name "system"}}
                "privateIPAddress": "[concat(variables('aciSystemNodeAddrPrefix'), copyIndex(add(50, int(variables('aciPrimaryIPOctet4')))))]",
                {{else if eq $.Name "agentpool1"}}
                "privateIPAddress": "[concat(variables('aciSystemNodeAddrPrefix'), copyIndex(add(100, int(variables('aciPrimaryIPOctet4')))))]",
                {{else}}
                "privateIPAddress": "[concat(variables('aciCustomerNodeAddrPrefix'), copyIndex(mul(25, sub(int(variables('{{$.Name}}Variables').{{$.Name}}Number), 2))), '.', variables('aciPrimaryIPOctet4'))]",
                {{end}}
              {{else if eq $.Name "system"}}
              "privateIPAddress": "[concat(variables('aciSystemPodAddrPrefix'), copyIndex(add(50, int(variables('aciPrimaryIPOctet4')))), '.', add(sub({{$seq}}, 1), int(variables('aciPrimaryIPOctet4'))))]",
              {{else if eq $.Name "agentpool1"}}
              "privateIPAddress": "[concat(variables('aciSystemPodAddrPrefix'), copyIndex(add(100, int(variables('aciPrimaryIPOctet4')))), '.', add(sub({{$seq}}, 1), int(variables('aciPrimaryIPOctet4'))))]",
              {{else}}
              "privateIPAddress": "[concat(variables('aciCustomerPodAddrPrefix'), copyIndex(mul(25, sub(int(variables('{{$.Name}}Variables').{{$.Name}}Number), 2))), '.', add(sub({{$seq}}, 1), int(variables('aciPrimaryIPOctet4'))))]",
              {{end}}
              "privateIPAllocationMethod": "Static",
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
      "name": "[variables('{{.Name}}Variables').{{.Name}}AvailabilitySet]",
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
      "name": "[variables('{{.Name}}Variables').{{.Name}}AvailabilitySet]",
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
        "[concat('Microsoft.Compute/availabilitySets/', variables('{{.Name}}Variables').{{.Name}}AvailabilitySet)]"
      ],
      "tags":
      {
        "creationSource" : "[concat(variables('generatorCode'), '-', variables('{{.Name}}Variables').{{.Name}}VMNamePrefix, copyIndex(variables('{{.Name}}Variables').{{.Name}}Offset))]",
        "resourceNameSuffix" : "[variables('nameSuffix')]",
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
          "id": "[resourceId('Microsoft.Compute/availabilitySets',variables('{{.Name}}Variables').{{.Name}}AvailabilitySet)]"
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
          "adminUsername": "[variables('username')]",
          "computername": "[concat(variables('{{.Name}}Variables').{{.Name}}VMNamePrefix, copyIndex(variables('{{.Name}}Variables').{{.Name}}Offset))]",
          {{GetKubernetesAgentCustomData .}}
          "linuxConfiguration": {
              "disablePasswordAuthentication": "true",
              "ssh": {
                "publicKeys": [
                  {
                    "keyData": "[parameters('sshRSAPublicKey')]",
                    "path": "[variables('sshKeyPath')]"
                  }
                ]
              }
            }
            {{if HasLinuxSecrets}}
              ,
              "secrets": "[variables('linuxProfileSecrets')]"
            {{end}}
        },
        "storageProfile": {
          {{GetDataDisks .}}
          "imageReference": {
            "offer": "[variables('{{.Name}}Variables').{{.Name}}osImageOffer]",
            "publisher": "[variables('{{.Name}}Variables').{{.Name}}osImagePublisher]",
            "sku": "[variables('{{.Name}}Variables').{{.Name}}osImageSKU]",
            "version": "[variables('{{.Name}}Variables').{{.Name}}osImageVersion]"
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
      "name": "[guid(concat('Microsoft.Compute/virtualMachines/', variables('{{.Name}}Variables').{{.Name}}VMNamePrefix, copyIndex(), 'vmidentity'))]",
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
         "type": "ManagedIdentityExtensionForLinux",
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
      "name": "[concat(variables('{{.Name}}Variables').{{.Name}}VMNamePrefix, copyIndex(variables('{{.Name}}Variables').{{.Name}}Offset),'/cse', copyIndex(variables('{{.Name}}Variables').{{.Name}}Offset))]",
      "properties": {
        "publisher": "Microsoft.Azure.Extensions",
        "type": "CustomScript",
        "typeHandlerVersion": "2.0",
        "autoUpgradeMinorVersion": true,
        "settings": {},
        "protectedSettings": {
          {{if eq $.Name "system"}}
          "commandToExecute": "[concat(variables('provisionScriptParametersCommon'),' /usr/bin/nohup /bin/bash -c \"/bin/bash /opt/azure/containers/provision.sh >> /var/log/azure/cluster-provision.log 2>&1\"')]"
          {{else if eq $.Name "agentpool1"}}
          "commandToExecute": "[concat(variables('provisionScriptParametersCommon'),' /usr/bin/nohup /bin/bash -c \"/bin/bash /opt/azure/containers/provision.sh >> /var/log/azure/cluster-provision.log 2>&1\"')]"
          {{else}}
          "commandToExecute": "[concat(variables('provisionScriptParametersCommon'),' /usr/bin/nohup /bin/bash -c \"/bin/bash /opt/azure/containers/provision.sh multitenancy >> /var/log/azure/cluster-provision.log 2>&1\"')]"
          {{end}}
        }
      }
    }
