<#
   Logoff when there is no operation for a certain period of time.
#>
# Parameters
Param (
   [Parameter(HelpMessage="Timeout minutes until logoff")][alias("Timeout","t")][ValidateRange(1,1440)][Int]$TimeoutMin = 1,
   [alias("Force","f")][Switch]$ForceFlag
)

$ActionInt = 0
if ($ForceFlag) {
   $ActionInt = $ActionInt + 4
}

# Modules
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

# Main Routine
$Timeout = [TimeSpan]::FromMinutes($TimeoutMin)
$Interval = [TimeSpan]::FromMilliseconds(850)
do {
   Start-Sleep -Milliseconds 1000
   $IdleTime = [PInvoke.Win32.UserInput]::IdleTime
   $TimeoutPercent = ($IdleTime.TotalSeconds / $Timeout.TotalSeconds) * 100
   Write-Progress -Activity "Idle Timeout until Logoff" -Status ([String][Math]::Round($IdleTime.Totalseconds, 2) + " seconds") -PercentComplete $TimeoutPercent
   if ($IdleTime -gt $Timeout) {
      Write-Host "See you again!"
      (Get-WmiObject -Class Win32_OperatingSystem -ComputerName .).Win32Shutdown($ActionInt)
   }
} while ($IdleTime -gt $Interval)

exit