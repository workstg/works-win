Option Explicit
On Error Resume Next
 
'サーバ固有IPアドレス
Const LocalIp = "192.168.0.11"
'共有VIP
Const SharedVip = "192.168.0.10"
'サブネットマスク（共通）
Const Subnet = "255.255.255.0"
 
Const GuardFile = "guard.tmp"
 
Dim objShell, objFS
Dim strArg, intIpStat, bolResult, i
 
Set objShell = WScript.CreateObject("WScript.Shell")
Set objFS = WScript.CreateObject("Scripting.FileSystemObject")
 
objShell.CurrentDirectory = objFS.GetParentFolderName(WScript.ScriptFullName) & "\."
 
'Main Routine
'多重実行防止
If objFS.FileExists(GuardFile) Then WScript.Quit(0)
 
'引数の判定
If WScript.Arguments.Unnamed.Count = 0 Then
   'VIPチェック
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
   '自ノードがVIPを保持している場合は削除
   If VipRemove(LocalIp, SharedVip, Subnet) Then
      WScript.Sleep(360000)
      objFS.DeleteFile GuardFile, True
      WScript.Quit(0)
   End If
   objFS.DeleteFile GuardFile, True
   WScript.Quit(1)
ElseIf intIpStat = 1 Then
   '他ノードVIPを保有している場合は何もせず終了
   WScript.Quit(0)
Else
   'ネットワーク上にVIPが存在しない場合は自ノードに付与
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
'VIPチェック (0 - Assign, 1 - Exist, 2 - Not exist)
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
 
'VIP消去 (True/False)
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
 
'VIP追加 (True/False)
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