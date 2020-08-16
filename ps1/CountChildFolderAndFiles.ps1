<#
Count sub folders and files
#>
# Parameters
$TargetPath = "\\127.0.0.1\Data"
$ResultTable = @()

# Main Routine
if (Test-Path -Path $TargetPath -PathType Container) {
   $SubFolders = Get-ChildItem -Path $TargetPath -Force | Where-Object { $_.PSIsContainer }
} else {
   Write-Output "The folder not found!"
   exit 1
}

foreach ($SubFolder in $SubFolders) {
   $Result = New-Object PSObject | Select-Object Name, NumFolders, NumFiles, TotalSize, TotalSizeMB
   $Result.Name = $SubFolder.Name

   $AllItems = Get-ChildItem -Path $SubFolder.FullName -Recurse -Force
   $Result.NumFolders = [double](($AllItems | Where-Object {$_.PsIsContainer}).Count)
   $Result.NumFiles = [double](($AllItems | Where-Object {! $_.PsIsContainer}).Count)
   $Result.TotalSize = [double](($AllItems | Measure-Object Length -Sum).Sum)
   $Result.TotalSizeMB = [math]::round(($AllItems | Measure-Object Length -Sum).Sum / 1MB, 2)

   $ResultTable += $Result
}
$ResultTable | Format-Table -AutoSize

exit