Param (
   [Parameter(Mandatory = $True, HelpMessage="Role name")][alias("name","n")][ValidateNotNullOrEmpty()][string]$RoleName,
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
   $OutFile = $PSScriptRoot + "\" + "$RoleName" + ".role"
   try {
      Get-VIRole -Name $RoleName | Get-VIPrivilege | Select-Object -ExpandProperty Id | Out-File -FilePath $OutFile
   } catch {
      Write-Error $_.Exceotion
      exit 1
   }
  
}
  
if ($ImportFlag) {
   $InFile = $PSScriptRoot + "\" + "$RoleName" + ".role"
   try {
      $RolePrivileges = Get-Content -Path $InFile
   } catch {
      Write-Error $_.Exceotion
      exit 2
   }
   New-VIRole -Name $RoleName
   foreach ($Privilege in $RolePrivileges) {
      if (-not ($null -eq $Privilege -or $Privilage -eq "")) {
         Set-VIRole -Role $RoleName -AddPrivilege (Get-VIPrivilege -Id $Privilege)
      }
   }
}
Disconnect-VIServer -Confirm:$False
exit