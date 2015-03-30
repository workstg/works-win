Option Explicit

Const TargetHost = ""
Const TargetPort = ""

Dim objXML, intRet, strStatus

Set objXML = WScript.CreateObject("MSXML2.ServerXMLHTTP")
objXML.SetTimeouts 10000,10000,10000,10000
intRet = "0"

On Error Resume Next
objXML.open "GET", "http://" & TargetHost & ":" & TargetPort, False
objXML.send
intRet = Err.Number

Select Case intRet
   Case 0,  -2147012744, -2147024891
      'TCP Connect success , no HTTP responce, 401 auth failure
      strStatus = "OK"
   Case -2147012867
      'Connection Rejected
      strStatus = "REJECTED"
   Case -2147012894
      'Timeout
      strStatus = "TIMEOUT"
   Case -2147012889
      'Could not resolve address
      strStatus = "UNKNOWN HOST"
   Case -2147467259
      'Cannot test that port with this tool
      strStatus = "SYSTEM ERROR"
   Case -2147012851
      'Certificate authority is invalid or incorrect
      strStatus = "CERTIFICATE INVALID"
   Case Else
      'Unknown error
      strStatus = "UNKNOWN ERROR"
End Select

On Error Goto 0
Set objXML = Nothing
WScript.Echo Now & " TCP: " & strStatus

WScript.Quit(0)