Option Explicit
On Error Resume Next

Const DsQuery = "C:\Windows\System32\dsquery user "
Const DsGet = "C:\Windows\System32\dsget user "
Const DsMod = "C:\Windows\System32\dsmod user "

Dim strCmd, strUser, cmdResult
Dim objShell, objExec, objRE
Dim aryUsers(), aryTemp(2)
Dim i, j

Set objRE = new RegExp
objRE.Pattern = ".*yes.*"

Set objShell = WScript.CreateObject("WScript.Shell")

i = 0
Set objExec = objShell.Exec(DsQuery)
Do While objExec.Status = 0
   WScript.Sleep 100
   If i >= 6000 Then
      objExec.Terminate
   End If
   i = i + 1
Loop

j = 0
Do Until objExec.StdOut.AtEndOfStream
   redim Preserve aryUsers(j)
   aryUsers(j) = objExec.StdOut.ReadLine
   j = j + 1
Loop

cmdResult = objExec.ExitCode
If cmdResult <> 0 Then
   WScript.Echo "ユーザー一覧の取得に失敗しました！！！"
   WScript.Quit(1)
End If

For Each strUser In aryUsers
   i = 0
   strCmd = DsGet & strUser & " -disabled"
   Set objExec = objShell.Exec(strCmd)
   Do While objExec.Status = 0
      WScript.Sleep 100
      If i >= 6000 Then
         objExec.Terminate
      End If
      i = i + 1
   Loop
   
   j = 0
   Do Until objExec.StdOut.AtEndOfStream
      aryTemp(j) = objExec.StdOut.ReadLine
      j = j + 1
   Loop

   If objRE.Test(aryTemp(1)) Then
      WScript.Echo strUser & "は無効です！！！"
   Else
      i = 0
      strCmd = DsMod & strUser & " -pwdneverexpires yes"
      Set objExec = objShell.Exec(strCmd)
      Do While objExec.Status = 0
         WScript.Sleep 100
         If i >= 6000 Then
            objExec.Terminate
         End If
         i = i + 1
      Loop

      cmdResult = objExec.ExitCode
      If cmdResult <> 0 Then
         WScript.Echo "ユーザー" & strUser & "の設定変更に失敗しました！！！"
         WScript.Quit(2)
      End If

      WScript.Echo "設定変更 : " & strUser
   End If

Next

WScript.Quit(0)
