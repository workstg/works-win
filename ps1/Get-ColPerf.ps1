$Counters = (
   "\Processor(_total)\% Idle Time",
   "\Memory\Available MBytes",
   "\Network Interface(*)\Bytes Total/sec"
)

Set-Location $PSScriptRoot
$MyHost = $Env:Computername
$DateTime = Get-Date -Format "yyyyMMddTHHmmss"
Write-Output "If closing data collection, press [Ctrl] + [C]."

Get-Counter -Counter $Counters -Continuous | foreach {
   $DataObject = New-Object PSObject | Add-Member -PassThru NoteProperty TimeStamp $_.TimeStamp
   $_.CounterSamples | foreach { 
      $DataObject | Add-Member NoteProperty $_.Path $_.CookedValue
   }

   $DataObject
} | Export-Csv -NoTypeInformation -Path .\PerfData-$MyHost-$DateTime.csv

exit