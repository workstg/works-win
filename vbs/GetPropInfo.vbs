Const TargetFileName = "Flash64_14_0_0_145.ocx"
Const TargetFilePath = "C:\Windows\System32\Macromed\flash"
Const CheckParameter = "���i�o�[�W����"
 
Dim objShell, objFS, objFolder, objFolderItem, RetVal, i
Dim arrParams(300)
Set objFS = WScript.CreateObject("Scripting.FileSystemObject")
 
If objFS.FileExists(TargetFilePath & "\" & TargetFileName) Then
   Set objShell = WScript.CreateObject("Shell.Application")
   Set objFolder = objShell.Namespace(TargetFilePath)
   Set objFolderItem = objFolder.ParseName(TargetFileName)
 
   For i = 0 To 300
      arrParams(i) = objFolder.GetDetailsOf(objFolder.Items, i)
      '�o�ߕ\���i����m�F�p�j
      'WScript.Echo arrParams(i) & " : " & objFolder.GetDetailsOf(objFolderItem, i)
 
      If lcase(arrParams(i)) = CheckParameter Then
         RetVal = objFolder.GetDetailsOf(objFolderItem, i)
         Exit For
      End If
   Next
End If
 
WScript.Echo RetVal
 
WScript.Quit(0)