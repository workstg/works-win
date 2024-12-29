# Import VM List file
$ListFile = "C:\Temp\vmlist.csv"
$VmList = Import-Csv $ListFile

# vSphere Resource
$VcServer = "vc.example.com"
$EsxHost = "esx.example.com"
$Template = "vm-template"
$SpecName = "Spec-Windows"
$Store = "Shared-Vol"
$FolderName = "Servers"

# Authentication
$VcAdmin = "Administrator@vsphere.local"
$VcPasswd = "password"

# Common Networking
$NetMask = "255.255.255.0"
$DefaultGw = "192.168.0.254"
$Dns = "192.168.0.1"

Import-Module VMware.PowerCLI
$Res = Connect-VIServer -Server $VcServer -User $VcAdmin -Password $VcPasswd
$VmFolder = Get-Folder -Name $FolderName

foreach ($TargetVm in $VmList) {
   $VmName = $TargetVm.Name
   $VmIpaddr = $TargetVm.IpAddress
   $TempSpec = "$VmName-Temp"

   $Res = Get-OSCustomizationSpec -Name $SpecName | New-OSCustomizationSpec -Name $TempSpec -Type NonPersistent
   $Res = Get-OSCustomizationNicMapping $TempSpec | Set-OSCustomizationNicMapping -IpMode UseStaticIP -IpAddress $VmIpaddr -SubnetMask $NetMask -DefaultGateway $DefaultGw -Dns $Dns
   Start-Sleep 3

   $Res = New-VM -Name $VmName -VMHost $EsxHost -Template $Template -OSCustomizationSpec $TempSpec -Datastore $Store -Location $VmFolder
   Start-Sleep 3

   $Res = Get-VM -Name $VmName | New-VTpm
   Start-Sleep 1
   Start-VM -VM $VmName
}

Disconnect-VIServer -Confirm:$false
exit