# To prevent malfunction
Param ([alias("-remove","r")][switch]$RemFrag)

$KeepAppxPackages = @(
   "Microsoft.MicrosoftStickyNotes",
   "Microsoft.WindowsCalculator",
   "Microsoft.ScreenSketch",
   "Microsoft.WindowsStore"
)

Write-Output "Start scripts."
# Remove Privisioned Appx Packages
$ProvisionedAppx = Get-AppxProvisionedPackage -Online

:RemPkg foreach ($PvAppx in $ProvisionedAppx){
   foreach ($KeepPkg in $KeepAppxPackages){
      if ($PvAppx.DisplayName -eq $KeepPkg){
         Write-Output "Skipping    : $($PvAppx.DisplayName)"
         continue RemPkg
      }
   }
   Write-Output "Removing    : $($PvAppx.DisplayName)"
   if ($RemFrag){
      Remove-AppxProvisionedPackage -Online -PackageName $PvAppx.PackageName
   }
}
Write-Output "------------"
# Uninstall Appx Packages
$InstalledAppx = Get-AppxPackage -AllUsers

:UnPkg foreach ($InAppx in $InstalledAppx){
   foreach ($KeepPkg in $KeepAppxPackages){
      if ($InAppx.Name -eq $KeepPkg){
         Write-Output "Skipping    : $($InAppx.Name)"
         continue UnPkg
      }
   }
   Write-Output "Uninstalling : $($InAppx.Name)"
   if ($RemFrag){
      Get-AppxPackage -AllUsers -Name $InAppx.Name | Remove-AppxPackage
   }
}
Write-Output "End scripts."
exit