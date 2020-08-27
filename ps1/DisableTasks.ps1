$TargetTasks = (
   "Microsoft Compatibility Appraiser",
   "ProgramDataUpdater",
   "StartupAppTask",
   "Proxy",
   "Consolidator",
   "UsbCeip",
   "ProactiveScan",
   "Scheduled",
   "Microsoft-Windows-DiskDiagnosticDataCollector",
   "Microsoft-Windows-DiskDiagnosticResolver",
   "ScheduledDefrag",
   "File History (maintenance mode)",
   "WinSAT",
   "ProcessMemoryDiagnosticEvents",
   "RunFullMemoryDiagnostic",
   "AnalyzeSystem",
   "VerifyWinRE",
   "RegIdleBackup",
   "SR",
   "ResolutionHost"
)

echo "�ȉ��̃^�X�N�𖳌��ɂ��܂����B"
echo "---"
foreach ($TaskName in $TargetTasks) {
   $Task = Get-ScheduledTask -TaskName $TaskName
   if (-Not ($Task.State -eq "Disabled")) {
      $Res = ($Task | Disable-ScheduledTask)
      $Res.TaskName
   }
}

echo "---"
Get-ScheduledTask
exit