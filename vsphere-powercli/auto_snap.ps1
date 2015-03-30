#vCenter Serverへの接続情報
$VC_HOST = "vcenter.domain.local"
$VC_USER = "vcenter_user"
$VC_PASSWORD = "vcenter_password"

# マスター用仮想マシンのvCenter上での名称
$MASTER_VM = "vm01"

# Recomposer対象のプールID
$RECOMP_POOL = "Float_Pool"

# vSphere/VMware View用のスナップイン呼び出し
Add-PSSnapin VMware.VimAutomation.Core
Add-PSSnapin VMware.View.Broker

# vCenter Serverへの接続
$VC_CONN = Connect-VIServer -Server $VC_HOST -User $VC_USER -Password $VC_PASSWORD

# マスター用仮想マシンのシャットダウン
Shutdown-VMGuest $MASTER_VM -Confirm:$False
Start-Sleep -s 300

# スナップショットの作成
$NOW = Get-Date -format yyyyMMddHHmm
New-Snapshot -Name $NOW -Description "Created by PowerCLI" -VM $MASTER_VM

# スナップショットパスの作成
$SNAP_PATH = ""
$SNAP_LIST = Get-Snapshot -VM $MASTER_VM
ForEach ($SNAPSHOT in $SNAP_LIST) {
   $SNAP_NAME = $SNAPSHOT.name
   $SNAP_PATH = $SNAP_PATH + "/" + $SNAP_NAME
}

# Recomposeパラメータの作成
$POOL_PARAM = Get-Pool -Pool_id $RECOMP_POOL
$MASTER_PATH = $POOL_PARAM.parentVMPath
$SCHED = ((Get-Date).AddHours(8))

# プールの基本イメージを変更
Update-AutomaticLinkedClonePool -Pool_id $RECOMP_POOL -parentVMPath $MASTER_PATH -parentSnapshotPath $SNAP_PATH

# Recomposeの実行
Get-DesktopVM -Pool_id $RECOMP_POOL | Send-LinkedCloneRecompose -schedule $SCHED -parentVMPath $MASTER_PATH -parentSnapshotPath $SNAP_PATH -forceLogoff $true -stopOnError $true
Start-Sleep -s 300

# 古いスナップショットの削除 (14日より過去に作られたスナップショット)
Get-Snapshot -VM $MASTER_VM | Where-Object { $_.Created -lt (Get-Date).AddDays(-14) } | Remove-Snapshot -Confirm:$False

# マスター用仮想マシンの起動
Start-VM -VM $MASTER_VM

# vCenter Serverから切断
Disconnect-VIServer -Server $VC_HOST -Confirm:$False

exit 0
