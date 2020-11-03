<#
   Send E-Mail if the flag file exists.
   Assuming execution with a log off script.
#>
# Configuration Files
$IdleNotifyRoot = $env:ALLUSERSPROFILE + "\Tools"
$AdminConfig = $IdleNotifyRoot + "\AdminConfig.json"
$MailFile = $IdleNotifyRoot + "\mail-logoff.txt"
$UserConfig = $Home + "\mailaddress.txt"
$WarnOutput = $Home + "\warn.log"
$LogoffFlag = $env:LocalAppData + "\Temp\logoffnotify.tmp"

if (Test-Path $LogoffFlag) {
   if (Test-Path $AdminConfig) {
      $Config = Get-Content $AdminConfig -Raw | ConvertFrom-Json
   } else {
      Write-Output "`"AdminConfig.json`" file not found." | Set-Content $WarnOutput
      exit 1
   }
   if (Test-Path $UserConfig) {
      $MailTo = (Get-Content $UserConfig | Select-Object -First 1).Trim()
      if ($MailTo -notmatch '^([a-zA-Z0-9])+([a-zA-Z0-9\._-])+([a-zA-Z0-9])+@([a-zA-Z0-9])+([a-zA-Z0-9\._-])+([a-zA-Z0-9])+$') {
         Write-Output "E-Mail Address format miss match." | Set-Content $WarnOutput
         exit 4
      }
   } else {
      Write-Output "`"mailaddress.txt`" file not found." | Set-Content $WarnOutput
      exit 2
   }
   if (Test-Path $MailFile) {
      $MailSubject = Get-Content $MailFile | Select-Object -First 1
      $MailBody = (Get-Content $MailFile | Select-Object -Skip 1) -join "`n"
   } else {
      Write-Output "`"mail-logoff.txt`" file not found." | Set-Content $WarnOutput
      exit 8
   }

   # for .NET 4.5 support
   function Encode-MailSubject($Subject) {
      $Encode = [System.Text.Encoding]::GetEncoding("ISO-2022-JP")
      $Base64 = [Convert]::ToBase64String($Encode.GetBytes($Subject))
      "=?{0}?B?{1}?=" -f "iso-2022-jp", $Base64
   }

   # Main Routine
   $SmtpClient = New-Object Net.Mail.SmtpClient($Config.mail.smtp, $Config.mail.port)
   $SmtpClient.EnableSsl = $false
   if ($Config.mail.auth.enabled -ne 0) {
      $SmtpClient.Credentials = New-Object Net.NetworkCredential($Config.mail.auth.user, $Config.mail.auth.password)
      if($Config.mail.auth.ssl -ne 0){
         $SmtpClient.EnableSsl = $true
      }
   }
   $MailSubject = Encode-MailSubject(Encode-MailSubject($MailSubject))
   $MailMassage = New-Object Net.Mail.MailMessage($Config.mail.from, $MailTo, $MailSubject, $MailBody)
   if (-Not([String]::IsNullOrEmpty($Config.mail.bcc))) {
      $MailMassage.Bcc.Add($Config.mail.bcc)
   }
   $MailMassage.BodyEncoding = [System.Text.Encoding]::GetEncoding("ISO-2022-JP")
   try {
      $SmtpClient.Send($MailMassage)
   } catch {
      $_.Exception.Message | Set-Content $WarnOutput
   }
}
exit