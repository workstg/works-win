Option Explicit
'On Error Resume Next

Const TargetProto = "udp"

Dim objShell, objExec, objRE, strLine, intPort, RetVal

If WScript.Arguments.Unnamed.Count = 0 Then
   WScript.Quit(255)
End If
intPort = WScript.Arguments.Unnamed(0)

RetVal = 0
Set objRE = new RegExp
objRE.Pattern = ".\:" & intPort & "\s"

Set objShell = WScript.CreateObject("WScript.Shell")
Set objExec = objShell.Exec("C:\Windows\System32\netstat.exe -an -p " & TargetProto)
Do While objExec.Status = 0
   WScript.Sleep 100
Loop

Do Until objExec.StdOut.AtEndOfStream
   strLine = objExec.StdOut.ReadLine
   If objRE.Test(strLine) Then
      RetVal = 1
   End If
Loop

WScript.Echo RetVal
WScript.Quit(0)

