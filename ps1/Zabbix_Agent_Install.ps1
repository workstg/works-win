<#
Zabbin Agent �C���X�g�[���X�N���v�g
* �Ǘ��Ҍ������K�v�ł��B
* �K�v�ɉ����Ď��O��"Set-ExecutionPolicy RemoteSigned"�����s���ĉ������B
#>
# ZIP�t�@�C��
$SourceURL = "http://www.zabbix.com/downloads/2.4.4/zabbix_agents_2.4.4.win.zip"
$TempDir = [Environment]::GetEnvironmentVariable("Temp")
$DestFile = $TempDir + "\zabbix_agent.zip"

# Zabbix Server
$ZabbixSrv = "172.16.11.14"

# �C���X�g�[���p�X
$ZabbixDir = "C:\Program Files\Zabbix"
$ZabbixCfg = $ZabbixDir + "\zabbix_agentd.conf"

# �_�E�����[�h
echo "Zabbix Agent �t�@�C�����_�E�����[�h���܂�"
Invoke-WebRequest -Uri $SourceURL -OutFile $DestFile

# �t�@�C���z�u
echo "Zabbix Agent �t�@�C����z�u���܂�"
New-Item $ZabbixDir -ItemType Directory

$ShellApp = New-Object -com Shell.Application
$ZipFile = $ShellApp.NameSpace($DestFile)
foreach($Item in $ZipFile.Items())
{
   $ShellApp.NameSpace($TempDir).Copyhere($Item)
}
Move-Item ($TempDir + "\bin\win64\zabbix_agentd.exe") $ZabbixDir
Move-Item ($TempDir + "\bin\win64\zabbix_get.exe") $ZabbixDir
Move-Item ($TempDir + "\bin\win64\zabbix_sender.exe") $ZabbixDir
Move-Item ($TempDir + "\conf\zabbix_agentd.win.conf") $ZabbixCfg

# �����ݒ�
echo "Zabbix Agent�̏����ݒ���s���܂�"
$HostName = Get-WmiObject Win32_ComputerSystem | Select -First 1 | foreach({"{0}.{1}" -F $_.Name,$_.Domain})

$Config = Get-Content $ZabbixCfg
$Config = $Config -replace "^Server=127\.0\.0\.1$",("Server=" + $ZabbixSrv)
$Config = $Config -replace "^ServerActive=127\.0\.0\.1$",("ServerActive=" + $ZabbixSrv)
$Config = $Config -replace "^Hostname=.*$",("Hostname=" + $HostName)
$Config = $Config -replace "^# HostMetadata=.*$",("# HostMetadata=`r`nHostMetadata=Windows")
$Config = $Config -replace "^# EnableRemoteCommands=.*$",("# EnableRemoteCommands=`r`nEnableRemoteCommands=1")
$Config = $Config -replace "^LogFile=.*$",("LogFile=" + $ZabbixDir + "\zabbix_agentd.log")
$Config | Set-Content $ZabbixCfg -Encoding ASCII

# Agent �C���X�g�[��
echo "Zabbix Agent���N�����܂�"
Start-Process -FilePath ($ZabbixDir + "\zabbix_agentd.exe") -ArgumentList "-i","-c",('"' + $ZabbixCfg + '"') -Wait

# Firewall �|�[�g�J��
echo "Windows �t�@�C�A�E�H�[���̃|�[�g���J�����܂�"
New-NetFirewallRule `
-Name "Zabbix Agent" `
-DisplayName "Zabbix Agent" `
-Description "for Zabbix Agent" `
-Group "Zabbix" `
-Enabled True `
-Profile Any `
-Direction Inbound `
-Action Allow `
-EdgeTraversalPolicy Block `
-LooseSourceMapping $False `
-LocalOnlyMapping $False `
-OverrideBlockRules $False `
-Program Any `
-LocalAddress Any `
-RemoteAddress Any `
-Protocol TCP `
-LocalPort 10050 `
-RemotePort Any `
-LocalUser Any `
-RemoteUser Any

echo "Zabbix Agent���C���X�g�[�����܂���"
exit
