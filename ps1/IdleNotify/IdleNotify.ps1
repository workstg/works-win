<#
   Send E-Mail when there is no operation for a certain period of time.
#>
# Configuration Files
$AdminConfig = $PSScriptRoot + "\AdminConfig.json"
$MailFile = $PSScriptRoot + "\mail.txt"
$UserConfig = $Home + "\mailaddress.txt"
$WarnOutput = $Home + "\warn.log"

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
   Write-Output "`"mail.txt`" file not found." | Set-Content $WarnOutput
   exit 8
}

Add-Type @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace PInvoke.Win32 {

   public static class UserInput {

      [DllImport("user32.dll", SetLastError=false)]
      private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

      [StructLayout(LayoutKind.Sequential)]
      private struct LASTINPUTINFO {
         public uint cbSize;
         public int dwTime;
      }

      public static DateTime LastInput {
         get {
            DateTime bootTime = DateTime.UtcNow.AddMilliseconds(-Environment.TickCount);
            DateTime lastInput = bootTime.AddMilliseconds(LastInputTicks);
            return lastInput;
         }
      }

      public static TimeSpan IdleTime {
         get {
            return DateTime.UtcNow.Subtract(LastInput);
         }
      }

      public static int LastInputTicks {
         get {
            LASTINPUTINFO lii = new LASTINPUTINFO();
            lii.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
            GetLastInputInfo(ref lii);
            return lii.dwTime;
         }
      }
   }
}
'@

# for .NET 4.5 support
function Encode-MailSubject($Subject) {
   $Encode = [System.Text.Encoding]::GetEncoding("ISO-2022-JP")
   $Base64 = [Convert]::ToBase64String($Encode.GetBytes($Subject))
   "=?{0}?B?{1}?=" -f "iso-2022-jp", $Base64
}

# Main Routine
$TimeoutMin = $Config.timeout.minutes
$IntervalSec = 2
if ($TimeoutMin -lt 1) {
   $TimeoutMin = 1
}

$IdleTime = [PInvoke.Win32.UserInput]::IdleTime
$Timeout = New-TimeSpan -Minutes $TimeoutMin
$Interval = New-TimeSpan -Seconds ($IntervalSec - 1)
do {
   Start-Sleep -Seconds $IntervalSec
   $IdleTime = [PInvoke.Win32.UserInput]::IdleTime
   if ($IdleTime -gt $Timeout) {
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
      $MailMassage.BodyEncoding = [System.Text.Encoding]::GetEncoding("ISO-2022-JP")
      try {
         $SmtpClient.Send($MailMassage)
      } catch {
         $_.Exception.Message | Set-Content $WarnOutput
      }
      break
   }
} while ($IdleTime -gt $Interval)
exit