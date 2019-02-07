#Requires -RunAsAdministrator


Install-Module -Name AzureRM

Login-AzureRmAccount

$ResourceGroupName = "DevOpsLab1RG"
$AzureAutomationAccountName = "DevOpsLab1"
$Location = "West Europe"

Remove-AzureRmResourceGroup -Name $ResourceGroupName -Confirm:$false
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
New-AzureRmAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AzureAutomationAccountName -location $location

#New-AzureRmAutomationAccount -ResourceGroupName $ResourceGroupName -Name "AzureRM" -Location $Location -Plan Free

$account = Get-AzureRmAutomationAccount | Where-Object {$_.AutomationAccountName -like $AzureAutomationAccountName}


Remove-AzureRmAutomationModule -Name "AzureRM"  -ResourceGroupName $ResourceGroupName -AutomationAccountName $AzureAutomationAccountName -Confirm:$false -ErrorAction SilentlyContinue
Remove-AzureRmAutomationModule -Name "AzureRM.Network"  -ResourceGroupName $ResourceGroupName -AutomationAccountName $AzureAutomationAccountName -Confirm:$false -ErrorAction SilentlyContinue
Remove-AzureRmAutomationModule -Name "AzureRM.Profile"  -ResourceGroupName $ResourceGroupName -AutomationAccountName $AzureAutomationAccountName -Confirm:$false  -ErrorAction SilentlyContinue
New-AzureRmAutomationModule -Name "AzureRM" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AzureAutomationAccountName -ContentLinkUri "https://www.powershellgallery.com/packages/AzureRM/5.5.0"
New-AzureRmAutomationModule -Name "AzureRM.Network" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AzureAutomationAccountName -ContentLinkUri "https://www.powershellgallery.com/packages/AzureRM.Network/5.3.0"
New-AzureRmAutomationModule -Name "AzureRM.Profile" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AzureAutomationAccountName -ContentLinkUri "https://www.powershellgallery.com/packages/AzureRM.profile/4.4.0"

New-AzureRmAutomationVariable -Name VM1Name -Value "vm1" -Encrypted $false -ResourceGroupName $ResourceGroupName -AutomationAccountName $AzureAutomationAccountName
New-AzureRmAutomationVariable -Name VM2Name -Value "vm2" -Encrypted $false -ResourceGroupName $ResourceGroupName -AutomationAccountName $AzureAutomationAccountName
New-AzureRmAutomationVariable -Name ResourceGroupName -Value $ResourceGroupName -Encrypted $false -ResourceGroupName $ResourceGroupName -AutomationAccountName $AzureAutomationAccountName
New-AzureRmAutomationVariable -Name UserName -Value "Student" -Encrypted $false -ResourceGroupName $ResourceGroupName -AutomationAccountName $AzureAutomationAccountName
New-AzureRmAutomationVariable -Name Password -Value "Pa55w.rd1234" -Encrypted $false -ResourceGroupName $ResourceGroupName -AutomationAccountName $AzureAutomationAccountName
New-AzureRmAutomationVariable -Name Location -Value "westeurope" -Encrypted $false -ResourceGroupName $ResourceGroupName -AutomationAccountName $AzureAutomationAccountName  

<#
$Sub = Get-AzureRmSubscription
cd "C:\Users\grossriederp\Desktop\"
.\New-RunAsAccount.ps1 -ResourceGroup $ResourceGroupName -AutomationAccountName $AzureAutomationAccountName -SubscriptionId $Sub.SubscriptionId -ApplicationDisplayName "Test" -SelfSignedCertPlainPassword "Superstarkblabla" -CreateClassicRunAsAccount $false
#>

#Remove-AzureRmAutomationRunbook -Name Provision-lab-textual-workflow-v1 -ResourceGroupName $ResourceGroupName -AutomationAccountName $AzureAutomationAccountName -Confirm:$false

Remove-Item .\Provision-lab-textual-workflow-v1.ps1 
wget -Uri https://raw.githubusercontent.com/Microsoft/PartsUnlimited/master/Labfiles/AZ-400T05_Implementing_Application_Infrastructure/M02/Provision-lab-textual-workflow-v1.ps1 -OutFile .\Provision-lab-textual-workflow-v1.ps1 
Import-AzureRmAutomationRunbook -Name Provision-lab-textual-workflow-v1 -Type PowerShellWorkflow -Description "Lel Noob" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AzureAutomationAccountName -Path ".\Provision-lab-textual-workflow-v1.ps1"
Publish-AzureRmAutomationRunbook -Name Provision-lab-textual-workflow-v1 -ResourceGroupName $ResourceGroupName -AutomationAccountName $AzureAutomationAccountName
#Start-AzureRmAutomationRunbook -Name Provision-lab-textual-workflow-v1 -ResourceGroupName $ResourceGroupName -AutomationAccountName $AzureAutomationAccountName

$vm1Name = "vm1"
$vm2Name = "vm2"
$username = "Student"
$password = "Pa55w.rd1234"
 

$vmSize = 'Standard_A1' 

$vnetName = $resourceGroupName + '-vnet1' 
$vnetPrefix = '10.0.0.0/16' 
$subnet1Name = 'subnet1' 
$subnet1Prefix = '10.0.0.0/24' 

$avSetName = $ResourceGroupName + '-avset1' 

$publisherName = 'MicrosoftWindowsServer' 
$offer = 'WindowsServer' 
$sku = '2016-Datacenter' 
$version = 'latest' 
$vmosDiskSize = 128 
 
$publicIpvm1Name = $resourceGroupName + $vm1Name + '-pip1' 
$publicIpvm2Name = $resourceGroupName + $vm2Name + '-pip1' 
 
$nic1Name = $resourceGroupName + $vm1Name + '-nic1' 
$nic2Name = $resourceGroupName + $vm2Name + '-nic1' 
 
$vm1osDiskName = $resourceGroupName + $vm1Name + 'osdisk' 
$vm2osDiskName = $resourceGroupName + $vm2Name + 'osdisk' 

$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force 
$credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $securePassword 
 
$avSet = New-AzureRmAvailabilitySet -ResourceGroupName $resourceGroupName -Name $avSetName -Location $location -PlatformUpdateDomainCount 5 -PlatformFaultDomainCount 3 
 
$subnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnet1Name -AddressPrefix $subnet1Prefix 
$vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetPrefix -Subnet $subnet
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
 
$vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName 

    
$publicIpvm1 = New-AzureRmPublicIpAddress -Name $publicIpvm1Name -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Dynamic 
$nic1 = New-AzureRmNetworkInterface -Name $nic1Name -ResourceGroupName $resourceGroupName -Location $location -SubnetId $vNet.Subnets[0].Id -PublicIpAddressId $publicIpvm1.Id 
$vm1 = New-AzureRmVMConfig -VMName $vm1Name -VMSize $vmSize -AvailabilitySetId $avSet.Id 
    
$randomnumber1 = Get-Random -Minimum 0 -Maximum 99999999 
$tempName1 = $resourceGroupName + $vm1Name + $randomnumber1 
$nameAvail1 = Get-AzureRmStorageAccountNameAvailability -Name $tempName1 
If ($nameAvail1.NameAvailable -ne $true) { 
    Do { 
        $randomNumber1 = Get-Random -Minimum 0 -Maximum 99999999 
        $tempName1 = $resourceGroupName + $vm1Name + $randomnumber1 
        $nameAvail1 = Get-AzureRmStorageAccountNameAvailability -Name $tempName1 
    } 
    Until ($nameAvail1.NameAvailable -eq $True) 
} 
$storageAccountName1 = $tempName1  
$storageAccount1 = New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName1 -SkuName "Standard_LRS" -Kind "Storage" -Location $location 
 
$vm1 = Set-AzureRmVMOperatingSystem -VM $vm1 -Windows -ComputerName $vm1Name -Credential $credentials -ProvisionVMAgent EnableAutoUpdate 
$vm1 = Set-AzureRmVMSourceImage -VM $vm1 -PublisherName $publisherName -Offer $offer -Skus $sku -Version $version   
$blobPath1 = 'vhds/' + $vm1osDiskName + '.vhd' 
$osDiskUri1 = $storageAccount1.PrimaryEndpoints.Blob.ToString() + $blobPath1 
$vm1 = Set-AzureRmVMOSDisk -VM $vm1 -Name $vm1osDiskName -VhdUri $osDiskUri1 -CreateOption fromImage 
 
$vm1 = Add-AzureRmVMNetworkInterface -VM $vm1 -Id $nic1.Id 
New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $vm1 

$vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName 
$publicIpvm2 = New-AzureRmPublicIpAddress -Name $publicIpvm2Name -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Dynamic 
$nic2 = New-AzureRmNetworkInterface -Name $nic2Name -ResourceGroupName $resourceGroupName -Location $location -SubnetId $vNet.Subnets[0].Id -PublicIpAddressId $publicIpvm2.Id 
$vm2 = New-AzureRmVMConfig -VMName $vm2Name -VMSize $vmSize -AvailabilitySetId $avSet.Id 
 
$randomnumber2 = Get-Random -Minimum 0 -Maximum 99999999 
$tempName2 = $resourceGroupName + $vm2Name + $randomnumber2 
$nameAvail2 = Get-AzureRmStorageAccountNameAvailability -Name $tempName2 
If ($nameAvail2.NameAvailable -ne $true) { 
    Do { 
        $randomNumber2 = Get-Random -Minimum 0 -Maximum 99999999 
        $tempName2 = $resourceGroupName + $vm2Name + $randomnumber2 
        $nameAvail2 = Get-AzureRmStorageAccountNameAvailability -Name $tempName2 
    } 
    Until ($nameAvail2.NameAvailable -eq $True) 
} 
$storageAccountName2 = $tempName2  
$storageAccount2 = New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName2 -SkuName "Standard_LRS" -Kind "Storage" -Location $location 
 
$vm2 = Set-AzureRmVMOperatingSystem -VM $vm2 -Windows -ComputerName $vm2Name -Credential $credentials -ProvisionVMAgent EnableAutoUpdate 
$vm2 = Set-AzureRmVMSourceImage -VM $vm2 -PublisherName $publisherName -Offer $offer -Skus $sku -Version $version 

$blobPath2 = 'vhds/' + $vm2osDiskName + '.vhd' 
$osDiskUri2 = $storageAccount2.PrimaryEndpoints.Blob.ToString() + $blobPath2 
$vm2 = Set-AzureRmVMOSDisk -VM $vm2 -Name $vm2osDiskName -VhdUri $osDiskUri2 -CreateOption fromImage 
 
$vm2 = Add-AzureRmVMNetworkInterface -VM $vm2 -Id $nic2.Id 
New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $vm2 
   
 

$publicIplbName = $resourceGroupName + 'lb-pip1' 
$feIplbConfigName = $resourceGroupName + '-felbipconfig' 
$beAddressPoolConfigName = $resourceGroupName + '-beipapconfig' 
$lbName = $resourceGroupName + 'lb' 
 
$publicIplb = New-AzureRmPublicIpAddress -Name $publicIplbName -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Dynamic 
$feIplbConfig = New-AzureRmLoadBalancerFrontendIpConfig -Name $feIplbConfigName -PublicIpAddress $publicIplb 
$beIpAaddressPoolConfig = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name $beAddressPoolConfigName 
$healthProbeConfig = New-AzureRmLoadBalancerProbeConfig -Name HealthProbe -RequestPath '\' -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2 
$lbrule = New-AzureRmLoadBalancerRuleConfig -Name HTTP -FrontendIpConfiguration $feIplbConfig -BackendAddressPool $beIpAaddressPoolConfig -Probe $healthProbe -Protocol Tcp -FrontendPort 80 -BackendPort 80 
$lb = New-AzureRmLoadBalancer -ResourceGroupName $resourceGroupName -Name $lbName -Location $location -FrontendIpConfiguration $feIplbConfig -LoadBalancingRule $lbrule -BackendAddressPool $beIpAaddressPoolConfig -Probe $healthProbeConfig    
$nic1 = Get-AzureRmNetworkInterface -Name $nic1Name -ResourceGroupName $resourceGroupName 
$nic1.IpConfigurations[0].LoadBalancerBackendAddressPools = $beIpAaddressPoolConfig 
$nic2 = Get-AzureRmNetworkInterface -Name $nic2Name -ResourceGroupName $resourceGroupName 
$nic2.IpConfigurations[0].LoadBalancerBackendAddressPools = $beIpAaddressPoolConfig 
 
Set-AzureRmNetworkInterface -NetworkInterface $nic1 
Set-AzureRmNetworkInterface -NetworkInterface $nic2 
