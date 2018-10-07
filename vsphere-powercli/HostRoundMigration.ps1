Param (
   [Parameter(Mandatory = $True, HelpMessage="Source ESXi Host")][alias("src","s")][ValidateNotNullOrEmpty()][string]$SrcEsx,
   [Parameter(Mandatory = $True, HelpMessage="Destination ESXi Hosts")][alias("dest","d")][ValidateNotNullOrEmpty()][array]$DestEsxs
)

$VcSv = "192.168.0.251"
$VcUser = "administrator@vsphere.local"
$VcPass = "password"

Import-Module VMware.PowerCLI
#Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer -Server $VcSv -User $VcUser -Password $VcPass

$TargetHosts = @()
Foreach ($DestEsx in $DestEsxs) {
   $TargetHosts += Get-VMHost -Name $DestEsx
}

$Cnt = 0
$PowerOnVms = Get-VM | Where-Object { $_.PowerState -eq "PoweredOn" }
Foreach ($TargetVm in $PowerOnVms) {
   if ($TargetVm.VMHost.Name -eq $SrcEsx) {
      try {
         Move-VM -VM $TargetVm -Destination $TargetHosts[$Cnt] -RunAsync:$True
      } catch {
         Write-Error $_.Exceotion
         exit 1
      }
      $Cnt++
      if ($Cnt -ge $TargetHosts.Length) {
         $Cnt = 0
      }
      Start-Sleep 10
   }
}

Disconnect-VIServer -Server $VcSv -Confirm:$False
