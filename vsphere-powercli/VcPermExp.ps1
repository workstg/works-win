Param (
   [Parameter(Mandatory = $True, HelpMessage="Target CSV file")][alias("file","f")][ValidateNotNullOrEmpty()][string]$FilePath,
   [alias("-export","e")][switch]$ExportFlag,
   [alias("-import","i")][switch]$ImportFlag
)
if ($ExportFlag -and $ImportFlag) {
   Write-Output "`"export`" and `"import`" are exclusive parameters."
   exit 255
}
   
$VcSv = "192.168.1.251"
$VcUser = "administrator@vsphere.local"
$VcPass = "password"
   
Import-Module VMware.PowerCLI
#Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer -Server $VcSv -User $VcUser -Password $VcPass
   
if ($ExportFlag) {
   $Perms = Get-VIPermission
   $PermArray = @()
   foreach($Perm in $Perms) {
      if ($Perm.Principal -notmatch "VSPHERE\.LOCAL\\(vpxd-.*|vsphere-webclient-.*|Administrator$|Administrators$)") {
         $PermParams = New-Object PSObject -Property @{
            Entity = $Perm.Entity
            Type = $Perm.EntityId.Split("-")[0]
            Principal = $Perm.Principal
            Role = $Perm.Role
            Propagate = $Perm.Propagate
         }
         $PermArray += $PermParams
      }
   }
   $PermArray | Select-Object -Property Entity,Type,Principal,Role,Propagate | Export-Csv -Path $FilePath -Encoding Default -NoType
}
   
if ($ImportFlag) {
   Import-Csv -Path $FilePath -Encoding Default | Foreach-Object {
      if ($_.Type -eq "Datacenter") {
         $ViObj = Get-Datacenter -Name $_.Entity
      } elseif ($_.Type -eq "ClusterComputeResource") {
         $ViObj = Get-Cluster -Name $_.Entity
      } elseif ($_.type -eq "HostSystem") {
         $ViObj = Get-VMHost -Name $_.Entity
      } elseif ($_.Type -eq "VirtualMachine") {
         $ViObj = Get-VM -Name $_.Entity
      } elseif ($_.Type -eq "Datastore") {
         $ViObj = Get-Datastore -Name $_.Entity
      } elseif ($_.Type -eq "DistributedVirtualPortgroup") {
         $ViObj = Get-VDPortgroup -Name $_.Entity
      } elseif ($_.Type -eq "Folder") {
         $ViObj = Get-Folder -Name $_.Entity
      }
      if ($_.Propagate -eq "TRUE") {
         $Prop = $True
      } else {
         $Prop = $False
      }
      New-VIPermission -Entity $ViObj -Principal $_.Principal -Role $_.Role -Propagate:$Prop
   }
}
Disconnect-VIServer -Confirm:$False
exit