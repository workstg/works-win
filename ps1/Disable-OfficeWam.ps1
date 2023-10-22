# Web Account Manager (WAM) is Authentication Framework
$DisableWam = $true

$RegPath = "HKCU:Software\Microsoft\Office\16.0\Common\Identity"
$RegList = ("DisableADALatopWAMOverride", "DisableAADWAM", "DisableMSAWAM", "DisableADALSharedCache")

if (! (Test-Path -LiteralPath $RegPath)) {
   Write-Output "Microsoft 365 Apps is not installed!"
   exit
}

if ($DisableWam) {
   $IdentityProperty = Get-ItemProperty -LiteralPath $RegPath
   foreach ($RegName in $RegList) {
      if ($null -ne $IdentityProperty.$RegName) {
         $Ret = Remove-ItemProperty -LiteralPath $RegPath -Name $RegName
      }
      $Ret = New-ItemProperty -LiteralPath $RegPath -Name $RegName -PropertyType 'DWord' -Value 1
   }
} else {
   foreach ($RegName in $RegList) {
      $Ret = Remove-ItemProperty -LiteralPath $RegPath -Name $RegName
   }
}
Get-ItemProperty -LiteralPath $RegPath
exit