# Parameters
$HostFile = $PSScriptRoot + "\hosts.txt"
$LogFolder = $PSScriptRoot + "\logs"

# Credential
$Credential = Get-Credential
#$SecureString = ConvertTo-SecureString "Password" -AsPlainText -Force
#$Credential = New-Object System.Management.Automation.PsCredential "DOMAIN\Administrator", $SecureString

# Import hosts list
$HostList = Get-Content $HostFile
if (!(Test-Path $LogFolder)) {
   New-Item $LogFolder -ItemType Directory
}

# Main Routine
#$ErrorActionPreference = "silentlycontinue"
foreach ($TargetHost in $HostList) {
   $NowDateTime = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
   $LogFile = $LogFolder + "\$TargetHost.txt"

   $Result = Invoke-Command -ScriptBlock {arp -a} -ComputerName $TargetHost -Credential $Credential

   Write-Output "$NowDateTime ------------------------------------------------------------" | Add-Content -Path $LogFile
   Write-Output $Result | Add-Content -Path $LogFile
}

exit