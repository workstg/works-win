' MyDNS(http://www.mydns.jp/)�̃A�h���X���X�V����T���v���X�N���v�g
Option Explicit
On Error Resume Next

Const strURL = "http://www.mydns.jp/login.html"
Const strUser = "MyDNS�̃��[�U�[ID"
Const strPasswd = "MyDNS�̃p�X���[�h"

Dim objXML
Dim strXMLDoc
Dim intRet

Call httpatach()
WScript.Echo strXMLDoc

' �e�X�g�p
'If intRet = 0 Then
'   WScript.Echo Now & " HTTP GET NG"
'Else
'   WScript.Echo Now & " HTTP GET OK [ HTTP CODE = " & intRet & " ]"
'End If
  
WScript.Quit(0)

Sub httpatach()
   Set objXML = WScript.CreateObject("MSXML2.XMLHTTP.3.0")
   intRet = "0"

   objXML.open "GET", strURL, False, strUser, strPasswd
   objXML.send

   strXMLDoc = objXML.responseText
   intRet = objXML.status

   Set objXML = Nothing

End Sub
