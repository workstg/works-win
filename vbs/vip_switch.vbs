Option Explicit
On Error Resume Next
 
'�T�[�o�ŗLIP�A�h���X
Const LocalIp = "192.168.0.11"
'���LVIP
Const SharedVip = "192.168.0.10"
'�T�u�l�b�g�}�X�N�i���ʁj
Const Subnet = "255.255.255.0"
 
Const GuardFile = "guard.tmp"
 
Dim objShell, objFS
Dim strArg, intIpStat, bolResult, i
 
Set objShell = WScript.CreateObject("WScript.Shell")
Set objFS = WScript.CreateObject("Scripting.FileSystemObject")
 
objShell.CurrentDirectory = objFS.GetParentFolderName(WScript.ScriptFullName) & "\."
 
'Main Routine
'���d���s�h�~
If objFS.FileExists(GuardFile) Then WScript.Quit(0)
 
'�����̔���
If WScript.Arguments.Unnamed.Count = 0 Then
   'VIP�`�F�b�N
   intIpStat = IpCheck(SharedVip)
Else
   Select Case WScript.Arguments.Unnamed(0)
      Case "Assign"
         If VipAssign(LocalIp, SharedVip, Subnet) Then WScript.Quit(0)
      Case "Remove"
         If VipRemove(LocalIp, SharedVip, Subnet) Then WScript.Quit(0)
      Case Else
         WScript.Echo "Usage: ""Assign"" or  ""Remove"""
   End Select
 
   WScript.Quit(255)
End If
 
If intIpStat = 0 Then
   objFS.CreateTextFile GuardFile, True
   '���m�[�h��VIP��ێ����Ă���ꍇ�͍폜
   If VipRemove(LocalIp, SharedVip, Subnet) Then
      WScript.Sleep(360000)
      objFS.DeleteFile GuardFile, True
      WScript.Quit(0)
   End If
   objFS.DeleteFile GuardFile, True
   WScript.Quit(1)
ElseIf intIpStat = 1 Then
   '���m�[�hVIP��ۗL���Ă���ꍇ�͉��������I��
   WScript.Quit(0)
Else
   '�l�b�g���[�N���VIP�����݂��Ȃ��ꍇ�͎��m�[�h�ɕt�^
   i = 0
   Do While True
      bolResult = VipAssign(LocalIp, SharedVip, Subnet)
      WScript.Sleep(3000)
      intIpStat = IpCheck(SharedVip)
      If intIpStat = 0 Then
         WScript.Quit(0)
      End If
 
      If i > 3 Then
         WScript.Quit(1)
      End If
      i = i + 1
      WScript.Sleep(10000)
   Loop
End If
 
WScript.Quit(0)
 
'Sub Routine
'VIP�`�F�b�N (0 - Assign, 1 - Exist, 2 - Not exist)
Function IpCheck(TargetIpAddress)
   Dim strIpAddress, strNic, strPingItem, colNics, colPingItems, RetVal
   RetVal = False
   IpCheck = 2
 
   Set colPingItems = GetObject("winmgmts:").ExecQuery("SELECT * FROM Win32_PingStatus WHERE Address = '" & TargetIpAddress & "'")
   For Each strPingItem In colPingItems
      If strPingItem.StatusCode = 0 Then
         RetVal = True
         IpCheck = 1
      End If
   Next
   Set colPingItems = Nothing
 
   If RetVal Then
      Set colNics = GetObject("winmgmts:").ExecQuery("Select * From Win32_NetworkAdapterConfiguration Where IPEnabled=True")
      For Each strNic In colNics
         For Each strIpAddress In strNic.IPAddress
            If strIpAddress = TargetIpAddress Then
               IpCheck = 0
            End If
         Next
      Next
      Set colNics = Nothing
   End If
End Function
 
'VIP���� (True/False)
Function VipRemove(LocalIpAddress, SharedIpAddress, SubnetMask)
   Dim strIpAddress, strNic, colNics, RetVal
   Dim arrIpList(0), arrSubnet(0)
 
   arrIpList(0) = LocalIpAddress
   arrSubnet(0) = SubnetMask
 
   Set colNics = GetObject("winmgmts:").ExecQuery("Select * From Win32_NetworkAdapterConfiguration Where IPEnabled=True")
   For Each strNic In colNics
      For Each strIpAddress In strNic.IPAddress
         If strIpAddress = SharedIpAddress Then
            RetVal = strNic.EnableStatic(arrIpList, arrSubnet)
         End If
      Next
   Next
   Set colNics = Nothing
 
   If RetVal = 0 Then
      VipRemove = True
   Else
      VipRemove = False
   End If
End Function
 
'VIP�ǉ� (True/False)
Function VipAssign(LocalIpAddress, SharedIpAddress, SubnetMask)
   Dim strIpAddress, strNic, colNics, RetVal
   Dim arrIpList, arrSubnet
 
   arrIpList = Array(LocalIpAddress, SharedIpAddress)
   arrSubnet = Array(SubnetMask, SubnetMask)
 
   Set colNics = GetObject("winmgmts:").ExecQuery("Select * From Win32_NetworkAdapterConfiguration Where IPEnabled=True")
   For Each strNic In colNics
      If strNic.IPAddress(0) = LocalIpAddress Then
         RetVal = strNic.EnableStatic(arrIpList, arrSubnet)
      End If
   Next
   Set colNics = Nothing
 
   If RetVal = 0 Then
      VipAssign = True
   Else
      VipAssign = False
   End If
End Function