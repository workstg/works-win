$VC = "127.0.0.1"
$VCAdmin = "administrator@vsphere.local"
$VCPassword = "password"
$TartgetVM = "vm01"

Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer -Force -Server $VC -User $VCAdmin -Password $VCPassword
$VMs = Get-VM

foreach ($VM in $VMs) {
   $NewUUID = [guid]::NewGuid() | % { $_ -replace "-",""} | % { $_ -replace '([a-z0-9]{2})','$1 '} | % {$_ -replace '^(.{23}) ','$1-'}
   if ($VM.Name -eq $TartgetVM) {
      echo "VM: " $VM.Name "New UUID: " $NewUUID
      $Spec = New-Object VMware.Vim.VirtualMachineConfigSpec
      $Spec.Uuid = $NewUUID
      $VM.ExtensionData.ReconfigVM_Task($Spec)
      Start-Sleep -s 3
   }
}

exit
