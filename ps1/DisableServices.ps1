$TargetServices = (
   "AJRouter",
   "ALG",
   "BthAvctpSvc",
   "BITS",
   "BDESVC",
   "wbengine",
   "bthserv",
   "BTAGService",
   "PeerDistSvc",
   "DPS",
   "WdiServiceHost",
   "WdiSystemHost",
   "EFS",
   "Fax",
   "fdPHost",
   "FDResPub",
   "vmicrdv",
   "vmicvss",
   "vmickvpexchange",
   "vmicguestinterface",
   "vmicshutdown",
   "vmicheartbeat",
   "vmicvmsession",
   "vmictimesync",
   "SharedAccess",
   "CscService",
   "defragsvc",
   "QWAVE",
   "SensorDataService",
   "SensrSvc",
   "SensorService",
   "ShellHWDetection",
   "SSDPSRV",
   "SysMain",
   "upnphost",
   "wcncsvc",
   "WerSvc",
   "WMPNetworkSvc",
   "WSearch",
   "WlanSvc",
   "WwanSvc",
   "XboxGipSvc",
   "XblGameSave",
   "XboxNetApiSvc",
   "XblAuthManager"
)

$ErrorActionPreference = "silentlycontinue"
echo "以下のサービスの自動起動を無効にしました。"
foreach ($ServiceName in $TargetServices) {
   if ($Service = Get-Service -Name $ServiceName) {
      if (-Not ($Service.StartType -eq "Disabled")) {
         Set-Service -Name $ServiceName -StartupType Disabled
         $DisplayName = $Service.DisplayName
         echo " `* $DisplayName"
      }
   }
}
echo "---"

Get-Service | Sort-Object -Property DisplayName | Format-Table -Property Name,StartType,Status,DisplayName -Autosize
exit