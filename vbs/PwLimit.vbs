Option Explicit
On Error Resume Next

Const MyDomain = "workslab.net"
Const DsQuery = "C:\Windows\System32\dsquery user "
Const ADS_UF_DONT_EXPIRE_PASSWD = &h10000

Dim strCmd, strUser, cmdResult, intUAC, MaxPwdAge, EffDays, ExpDay
Dim objShell, objExec, objRE, objDom, objUser
Dim aryUsers()
Dim i, j

Set objRE = new RegExp
objRE.Pattern = """([^""]*)"""

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

WScript.Echo "ユーザー名,有効期間,最終更新,期限"

For Each strUser In aryUsers
   Set objDom = GetObject("LDAP://" & MyDomain)
   Set objUser = GetObject("LDAP://" & MyDomain & "/" & objRE.Replace(strUser, "$1"))

   intUAC = objUser.Get("userAccountControl")
   If intUAC And ADS_UF_DONT_EXPIRE_PASSWD Then
      EffDays = "Not Expire"
      ExpDay = "-"
   Else
      Set MaxPwdAge = objDom.Get("maxPwdAge")
      EffDays = CCur((MaxPwdAge.HighPart * 2 ^ 32) + MaxPwdAge.LowPart) / CCur(-864000000000)
      ExpDay = DateAdd("d", EffDays, objUser.PasswordLastChanged)
   End If

   WScript.Echo objUser.sAMAccountName & "," & EffDays & "," & objUser.PasswordLastChanged & "," & ExpDay
Next

WScript.Quit(0)
