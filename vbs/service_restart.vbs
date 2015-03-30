Option Explicit
On Error Resume Next
 
Dim objShell, objFS
Dim strService, strState, balResult
Dim intErrCode
 
Set objShell = WScript.CreateObject("WScript.Shell")
Set objFS = WScript.CreateObject("Scripting.FileSystemObject")
 
objShell.CurrentDirectory = objFS.GetParentFolderName(WScript.ScriptFullName) & "\."
 
'�����̔���
If WScript.Arguments.Unnamed.Count = 0 Then
   WScript.Quit(255)
End If
strService = WScript.Arguments.Unnamed(0)
 
'Mani Routine
strState = ServiceState(strService)
Select Case strState
   Case "Running"
      '�T�[�r�X�����삵�Ă���ꍇ�́u�ċN���v
      If StopService(strService) Then
         WScript.Sleep(1000)
         balResult = StartService(strService)
      End If
   Case "Stopped"
      '�T�[�r�X����~���Ă���ꍇ�́u�N���v
      balResult = StartService(strService)
   Case "Empty"
      '�T�[�r�X�����݂��Ȃ��ꍇ�͏I��
      WScript.Quit(2)
End Select
 
If balResult = False Then
   WScript.Quit(1)
End If
 
WScript.Quit(0)
 
'Sub Routine
'�T�[�r�X�̏�� (Running/Stopped/Empty)
Function ServiceState(ServiceName)
   Dim strSvc, colSvcs
   Set colSvcs = GetObject("winmgmts:").ExecQuery("Select * from Win32_Service Where Name='" & ServiceName & "'")
   If colSvcs.Count = 0 Then
      ServiceState = "Empty"
   Else
      For Each strSvc in colSvcs
         ServiceState = strSvc.State
         Exit For
      Next
   End If
End Function
 
'�T�[�r�X�̊J�n (True/False)
Function StartService(ServiceName)
   Dim strSvc, colSvcs, RetVal
   Set colSvcs = GetObject("winmgmts:").ExecQuery("Select * from Win32_Service Where Name='" & ServiceName & "'")
   If colSvcs.Count = 0 Then
      StartService = False
   Else
      StartService = False
      For Each strSvc in colSvcs
         RetVal = strSvc.StartService()
         Select Case RetVal
            Case 0
               'Service Started
               StartService = True
            Case 10
               'Service Running
               StartService = True
            Case Else
               'Other
               StartService = False
         End Select
         Exit For
      Next
   End If
End Function
 
'�T�[�r�X�̒�~ (True/False)
Function StopService(ServiceName)
   Dim strSvc, colSvcs, RetVal
   Set colSvcs = GetObject("winmgmts:").ExecQuery("Select * from Win32_Service Where Name='" & ServiceName & "'")
   If colSvcs.Count = 0 Then
      StopService = False
   Else
      StopService = False
      For Each strSvc in colSvcs
         RetVal = strSvc.StopService()
         Select Case RetVal
            Case 0
               'Service Stopped
               StopService = True
            Case 5
               'Service Already Stopped
               StopService = True
            Case Else
               'Other
               SoptService = False
         End Select
         Exit For
      Next
   End If
End Function