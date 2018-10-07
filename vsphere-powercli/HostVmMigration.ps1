Param (
   [Parameter(Mandatory = $True, HelpMessage="Source ESXi Host")][alias("src","s")][ValidateNotNullOrEmpty()][string]$SrcEsx,
   [Parameter(Mandatory = $True, HelpMessage="Destination ESXi Host")][alias("dest","d")][ValidateNotNullOrEmpty()][string]$DestEsx
)
 
$VcSv = "192.168.0.251"
$VcUser = "administrator@vsphere.local"
$VcPass = "password"
 
Import-Module VMware.PowerCLI
#Add-PSSnapin VMware.VimAutomation.Core
 
Connect-VIServer -Server $VcSv -User $VcUser -Password $VcPass
$TargetHost = Get-VMHost -Name $DestEsx
$PowerOnVms = Get-VM | Where-Object { $_.PowerState -eq "PoweredOn" }
Foreach ($TargetVm in $PowerOnVms) {
   if ($TargetVm.VMHost.Name -eq $SrcEsx) {
      try {
         Move-VM -VM $TargetVm -Destination $TargetHost -RunAsync:$True
      } catch {
         Write-Error $_.Exceotion
         exit 1
      }
      Start-Sleep 30
   }
}
 
Disconnect-VIServer -Server $VcSv -Confirm:$False