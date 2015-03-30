Option Explicit
On Error Resume Next

Const ADS_UF_DONT_EXPIRE_PASSWD = &h10000
Dim cmdResult, strLogFile, strLine, strCmd, strUser, intUAC, strMailBody, i, j
Dim objShell, objFS, objFile, objUser
Dim arrUsers, intMaxPwdDays, dtmExpDay, intVal, MailTo

Set objShell = WScript.CreateObject("WScript.Shell")
Set objFS = WScript.CreateObject("Scripting.FileSystemObject")
objShell.CurrentDirectory = objFS.GetParentFolderName(WScript.ScriptFullName)

'�O���t�@�C���̓ǂݍ���
ExecuteGlobal objFS.OpenTextFile(".\config.vbs").ReadAll

'���O�t�@�C��������
strLogFile = "pwnotify.csv"
objFS.CreateTextFile strLogFile, True
Set objFile = objFS.OpenTextFile(strLogFile, 2)
objFile.WriteLine "DateTime : " & Now
objFile.WriteLine "User,E-Mail,PasswordLastChanged,ExpirationDate,Status"
objFile.Close

'Main Routine
'���[�U�[��LDAP�p�X�擾
arrUsers = Split(GetLdapPaths(Domain), ";")

'�p�X���[�h�����̃`�F�b�N
For Each strUser In arrUsers
   Set objUser = GetObject(strUser)

   intUAC = objUser.Get("userAccountControl")
   If intUAC And ADS_UF_DONT_EXPIRE_PASSWD Then
      '���������[�U�[�̏���
      strLine = objUser.sAMAccountName & "," & objUser.mail & "," & objUser.PasswordLastChanged & ",None,Permanent"
   Else
      intMaxPwdDays = GetMaxPwdDays(Domain)
      dtmExpDay = DateAdd("d", intMaxPwdDays, objUser.PasswordLastChanged)
      intVal = intMaxPwdDays - Int(Now - objUser.PasswordLastChanged)

      '�����؂ꃆ�[�U�[�փ��[�����M
      If CheckExcludeUser(objUser.sAMAccountName, ExcludeUser) Then
         '���O���[�U�[�̏���
         strLine = objUser.sAMAccountName & "," & objUser.mail & "," & objUser.PasswordLastChanged & "," & dtmExpDay & ",Exclusion"
      Else
         If intVal <= NotifyLimit Then
            '���[�����M�Ώۃ��[�U�[�̏���
            strMailBody = "To: " & objUser.sAMAccountName & Chr(13) & Chr(10) & Chr(13) & Chr(10) & "Windows�̃p�X���[�h�X�V�����܂ŁA����" & intVal & "���ł��B" & Chr(13) & Chr(10) & "�����܂łɃp�X���[�h��ύX���Ă��������B"
            If Len(objUser.mail) = 0 Then
               MailTo = DefaultTo
            Else
               MailTo = objUser.mail & "," & DefaultTo
            End If
            '���[�����M���s
            cmdResult = SendMsg(SmtpServer, EnableSmtpAuth, SmtpUser, SmtpPassword, MailFrom, MailTo, MailSubject, strMailBody)
            If cmdResult Then
               strLine = objUser.sAMAccountName & "," & objUser.mail & "," & objUser.PasswordLastChanged & "," & dtmExpDay & ",Send Mail"
            Else
               strLine = objUser.sAMAccountName & "," & objUser.mail & "," & objUser.PasswordLastChanged & "," & dtmExpDay & ",Send Error"
            End If
         Else
            '���[�����M�ΏۊO���[�U�[�̏���
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
   '�ڑ��v���p�e�B
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

'�p�X���[�h�L�������i�h���C���|���V�[�j
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

'���O���[�U�[����
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

'���[�����M
Function SendMsg(strSmtp, bolSmtpAuth, strSmtpUser, strSmtpPass, strFrom, strTo, strSubject, strBody)
   Dim objMsg, strSchem, intPort, bolSmtpAuth
   strSchem = "http://schemas.microsoft.com/cdo/configuration/"
   intPort = 25
   Set objMsg = CreateObject("CDO.Message")

   'SMTP�F�؂��g�p����ꍇ
   If bolSmtpAuth Then
      objMsg.Configuration.Fields.Item(strSchem & "sendusername") = strSmtpUser
      objMsg.Configuration.Fields.Item(strSchem & "sendpassword") = strSmtpPass
      objMsg.Configuration.Fields.Item(strSchem & "smtpauthenticate") = 1
      'SMTP over SSL���g�p����ꍇ
      'objMsg.Configuration.Fields.Item(strSchem & "smtpusessl") = True
   End If

   '�A�h���X����`
   objMsg.From = strFrom
   objMsg.To = strTo
   'objMsg.Cc = strCc
   'objMsg.Bcc = strBcc

   '����/�{����`/�Y�t�t�@�C��
   objMsg.Subject = strSubject
   objMsg.TextBody = strBody
   objMsg.TextBodyPart.Charset = "ISO-2022-JP"
   '�Y�t�t�@�C��
   'objMsg.AddAttachment(strAttacheFile)

   'SMTP�T�[�o��`
   objMsg.Configuration.Fields.Item(strSchem & "sendusing") = 2
   objMsg.Configuration.Fields.Item(strSchem & "smtpserver") = strSmtp
   objMsg.Configuration.Fields.Item(strSchem & "smtpserverport") = intPort

   '���[�����M
   objMsg.Configuration.Fields.Update
   objMsg.Send
   If Err.Number = 0 or Err.Number = -2147463155 Then
      SendMsg = True
   Else
      SendMsg = False
   End If
End Function
