<#
Count sub folders and files
#>
# Parameters
$TargetPath = "\\127.0.0.1\Data"
$ResultTable = @()

# Main Routine
$SubFolders = Get-ChildItem -Path $TargetPath -Force | Where-Object { $_.PSIsContainer }

foreach ($SubFolder in $SubFolders) {
   $Result = New-Object PSObject | Select-Object Name, NumFolders, NumFiles, TotalSize, TotalSizeMB
   $Result.Name = $SubFolder.Name

   $AllItems = Get-ChildItem -Path $SubFolder.FullName -Recurse -Force
   $Result.NumFolders = [int64](($AllItems | Where-Object {$_.PsIsContainer}).Count)
   $Result.NumFiles = [int64](($AllItems | Where-Object {! $_.PsIsContainer}).Count)
   $Result.TotalSize = [int64](($AllItems | Measure-Object Length -Sum).Sum)
   $Result.TotalSizeMB = [math]::round(($AllItems | Measure-Object Length -Sum).Sum / 1MB, 2)

   $ResultTable += $Result
}
$ResultTable | Format-Table -AutoSize

exit