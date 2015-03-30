#vCenter Server�ւ̐ڑ����
$VC_HOST = "vcenter.domain.local"
$VC_USER = "vcenter_user"
$VC_PASSWORD = "vcenter_password"

# �}�X�^�[�p���z�}�V����vCenter��ł̖���
$MASTER_VM = "vm01"

# Recomposer�Ώۂ̃v�[��ID
$RECOMP_POOL = "Float_Pool"

# vSphere/VMware View�p�̃X�i�b�v�C���Ăяo��
Add-PSSnapin VMware.VimAutomation.Core
Add-PSSnapin VMware.View.Broker

# vCenter Server�ւ̐ڑ�
$VC_CONN = Connect-VIServer -Server $VC_HOST -User $VC_USER -Password $VC_PASSWORD

# �}�X�^�[�p���z�}�V���̃V���b�g�_�E��
Shutdown-VMGuest $MASTER_VM -Confirm:$False
Start-Sleep -s 300

# �X�i�b�v�V���b�g�̍쐬
$NOW = Get-Date -format yyyyMMddHHmm
New-Snapshot -Name $NOW -Description "Created by PowerCLI" -VM $MASTER_VM

# �X�i�b�v�V���b�g�p�X�̍쐬
$SNAP_PATH = ""
$SNAP_LIST = Get-Snapshot -VM $MASTER_VM
ForEach ($SNAPSHOT in $SNAP_LIST) {
   $SNAP_NAME = $SNAPSHOT.name
   $SNAP_PATH = $SNAP_PATH + "/" + $SNAP_NAME
}

# Recompose�p�����[�^�̍쐬
$POOL_PARAM = Get-Pool -Pool_id $RECOMP_POOL
$MASTER_PATH = $POOL_PARAM.parentVMPath
$SCHED = ((Get-Date).AddHours(8))

# �v�[���̊�{�C���[�W��ύX
Update-AutomaticLinkedClonePool -Pool_id $RECOMP_POOL -parentVMPath $MASTER_PATH -parentSnapshotPath $SNAP_PATH

# Recompose�̎��s
Get-DesktopVM -Pool_id $RECOMP_POOL | Send-LinkedCloneRecompose -schedule $SCHED -parentVMPath $MASTER_PATH -parentSnapshotPath $SNAP_PATH -forceLogoff $true -stopOnError $true
Start-Sleep -s 300

# �Â��X�i�b�v�V���b�g�̍폜 (14�����ߋ��ɍ��ꂽ�X�i�b�v�V���b�g)
Get-Snapshot -VM $MASTER_VM | Where-Object { $_.Created -lt (Get-Date).AddDays(-14) } | Remove-Snapshot -Confirm:$False

# �}�X�^�[�p���z�}�V���̋N��
Start-VM -VM $MASTER_VM

# vCenter Server����ؒf
Disconnect-VIServer -Server $VC_HOST -Confirm:$False

exit 0
