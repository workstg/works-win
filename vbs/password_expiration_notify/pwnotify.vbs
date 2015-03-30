Option Explicit
On Error Resume Next

Const ADS_UF_DONT_EXPIRE_PASSWD = &h10000
Dim cmdResult, strLogFile, strLine, strCmd, strUser, intUAC, strMailBody, i, j
Dim objShell, objFS, objFile, objUser
Dim arrUsers, intMaxPwdDays, dtmExpDay, intVal, MailTo

Set objShell = WScript.CreateObject("WScript.Shell")
Set objFS = WScript.CreateObject("Scripting.FileSystemObject")
objShell.CurrentDirectory = objFS.GetParentFolderName(WScript.ScriptFullName)

'外部ファイルの読み込み
ExecuteGlobal objFS.OpenTextFile(".\config.vbs").ReadAll

'ログファイル初期化
strLogFile = "pwnotify.csv"
objFS.CreateTextFile strLogFile, True
Set objFile = objFS.OpenTextFile(strLogFile, 2)
objFile.WriteLine "DateTime : " & Now
objFile.WriteLine "User,E-Mail,PasswordLastChanged,ExpirationDate,Status"
objFile.Close

'Main Routine
'ユーザーのLDAPパス取得
arrUsers = Split(GetLdapPaths(Domain), ";")

'パスワード期限のチェック
For Each strUser In arrUsers
   Set objUser = GetObject(strUser)

   intUAC = objUser.Get("userAccountControl")
   If intUAC And ADS_UF_DONT_EXPIRE_PASSWD Then
      '無期限ユーザーの処理
      strLine = objUser.sAMAccountName & "," & objUser.mail & "," & objUser.PasswordLastChanged & ",None,Permanent"
   Else
      intMaxPwdDays = GetMaxPwdDays(Domain)
      dtmExpDay = DateAdd("d", intMaxPwdDays, objUser.PasswordLastChanged)
      intVal = intMaxPwdDays - Int(Now - objUser.PasswordLastChanged)

      '期限切れユーザーへメール送信
      If CheckExcludeUser(objUser.sAMAccountName, ExcludeUser) Then
         '除外ユーザーの処理
         strLine = objUser.sAMAccountName & "," & objUser.mail & "," & objUser.PasswordLastChanged & "," & dtmExpDay & ",Exclusion"
      Else
         If intVal <= NotifyLimit Then
            'メール送信対象ユーザーの処理
            strMailBody = "To: " & objUser.sAMAccountName & Chr(13) & Chr(10) & Chr(13) & Chr(10) & "Windowsのパスワード更新期限まで、あと" & intVal & "日です。" & Chr(13) & Chr(10) & "期限までにパスワードを変更してください。"
            If Len(objUser.mail) = 0 Then
               MailTo = DefaultTo
            Else
               MailTo = objUser.mail & "," & DefaultTo
            End If
            'メール送信実行
            cmdResult = SendMsg(SmtpServer, EnableSmtpAuth, SmtpUser, SmtpPassword, MailFrom, MailTo, MailSubject, strMailBody)
            If cmdResult Then
               strLine = objUser.sAMAccountName & "," & objUser.mail & "," & objUser.PasswordLastChanged & "," & dtmExpDay & ",Send Mail"
            Else
               strLine = objUser.sAMAccountName & "," & objUser.mail & "," & objUser.PasswordLastChanged & "," & dtmExpDay & ",Send Error"
            End If
         Else
            'メール送信対象外ユーザーの処理
            strLine = objUser.sAMAccountName & "," & objUser.mail & "," & objUser.PasswordLastChanged & "," & dtmExpDay & ",Not Expired"
         End If
      End If
   End If
   Set objFile = objFS.OpenTextFile(strLogFile, 8)
   objFile.WriteLine strLine
   objFile.Close
Next

WScript.Quit(0)

'Sub Routine
Function GetLdapPaths(Fqdn)
   Dim objConn, objCmd, objRecSet
   Dim arrDn, strDn, strPathLine, n
   arrDn = Split(Fqdn, ".")
   For n = 0 To UBound(arrDn)
      If n = 0 Then
         strDn = "DC=" & arrDn(n)
      Else
         strDn = strDn & ",DC=" & arrDn(n)
      End If
   Next

   Set objConn = CreateObject("ADODB.Connection")
   Set objCmd = CreateObject("ADODB.Command")
   objConn.Provider = "ADsDSOObject"
   objConn.Open "Active Directory Provider"
   objCmd.ActiveConnection = objConn
   '接続プロパティ
   objCmd.Properties("Page Size") = 1000
   objCmd.Properties("Timeout") = 30
   objCmd.Properties("Searchscope") = 5
   objCmd.Properties("Cache Results") = False

   objCmd.CommandText = "SELECT AdsPath FROM 'LDAP://" & strDn & "' WHERE objectCategory='user'"
   Set objRecSet = objCmd.Execute
   objRecSet.MoveFirst

   strPathLine = objRecSet.Fields("AdsPath").Value
   objRecSet.MoveNext
   Do Until objRecSet.EOF
      strPathLine = strPathLine & ";" & objRecSet.Fields("AdsPath").Value
      objRecSet.MoveNext
   Loop

   objConn.Close
   Set objCmd = Nothing

   GetLdapPaths = strPathLine
End Function

'パスワード有効日数（ドメインポリシー）
Function GetMaxPwdDays(Fqdn)
   Dim objDom, objMaxPwdAge
   Dim arrDn, strDn, maxPwdNano, maxPwdSecs, n
   arrDn = Split(Fqdn, ".")
   For n = 0 To UBound(arrDn)
      If n = 0 Then
         strDn = "DC=" & arrDn(n)
      Else
         strDn = strDn & ",DC=" & arrDn(n)
      End If
   Next
   
   Set objDom = GetObject("LDAP://" & strDn)
   Set objMaxPwdAge = objDom.Get("maxPwdAge")
   GetMaxPwdDays = CCur((objMaxPwdAge.HighPart * 2 ^ 32) + objMaxPwdAge.LowPart) / CCur(-864000000000)
   
   Set objDom = Nothing
End Function

'除外ユーザー判定
Function CheckExcludeUser(TargetUser,ExcludeList)
   Dim arrExcludeUsers, tmpUser
   CheckExcludeUser = False
   arrExcludeUsers = Split(ExcludeList, ";")
   For Each tmpUser In arrExcludeUsers
      If LCase(tmpUser) = LCase(TargetUser) Then
         CheckExcludeUser = True
         Exit For
      End If
   Next
End Function

'メール送信
Function SendMsg(strSmtp, bolSmtpAuth, strSmtpUser, strSmtpPass, strFrom, strTo, strSubject, strBody)
   Dim objMsg, strSchem, intPort, bolSmtpAuth
   strSchem = "http://schemas.microsoft.com/cdo/configuration/"
   intPort = 25
   Set objMsg = CreateObject("CDO.Message")

   'SMTP認証を使用する場合
   If bolSmtpAuth Then
      objMsg.Configuration.Fields.Item(strSchem & "sendusername") = strSmtpUser
      objMsg.Configuration.Fields.Item(strSchem & "sendpassword") = strSmtpPass
      objMsg.Configuration.Fields.Item(strSchem & "smtpauthenticate") = 1
      'SMTP over SSLを使用する場合
      'objMsg.Configuration.Fields.Item(strSchem & "smtpusessl") = True
   End If

   'アドレス情報定義
   objMsg.From = strFrom
   objMsg.To = strTo
   'objMsg.Cc = strCc
   'objMsg.Bcc = strBcc

   '件名/本文定義/添付ファイル
   objMsg.Subject = strSubject
   objMsg.TextBody = strBody
   objMsg.TextBodyPart.Charset = "ISO-2022-JP"
   '添付ファイル
   'objMsg.AddAttachment(strAttacheFile)

   'SMTPサーバ定義
   objMsg.Configuration.Fields.Item(strSchem & "sendusing") = 2
   objMsg.Configuration.Fields.Item(strSchem & "smtpserver") = strSmtp
   objMsg.Configuration.Fields.Item(strSchem & "smtpserverport") = intPort

   'メール送信
   objMsg.Configuration.Fields.Update
   objMsg.Send
   If Err.Number = 0 or Err.Number = -2147463155 Then
      SendMsg = True
   Else
      SendMsg = False
   End If
End Function
