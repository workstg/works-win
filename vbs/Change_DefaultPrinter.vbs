Option Explicit
On Error Resume Next
 
Dim objWshNetWork, strPrinterName
Set objWshNetWork = WScript.CreateObject("WScript.NetWork")
 
' プリンタ名を指定
strPrinterName = "Microsoft XPS Document Writer"
 
objWshNetWork.SetDefaultPrinter strPrinterName
If Err.Number = 0 then
Else
WScript.Echo "エラーが発生しました : " & Err.Description
End If
Set objWshNetWork = Nothing
 
WScript.Quit(0)