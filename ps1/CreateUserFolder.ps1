<#
フォルダリダイレクト用フォルダの作成
#>
# Parameters
$DomainBios = "DOMAIN"
$TargetGroup = "Domain Users"
$RootFolder = "\\127.0.0.1\Shared"

# Main Routine
$GroupUsers = Get-ADGroupMember -Identity $TargetGroup -Recursive
$Folders = Get-ChildItem -Path $RootFolder

foreach ($DomainUser in $GroupUsers) {
   $Stat = $true
   foreach ($UserFolder in $Folders) {
      if ($DomainUser.SamAccountName -ieq $UserFolder.Name) {
         Write-Output "`"$UserFolder`" is already exist."
         $Stat = $false
      }
   }
   if ($Stat) {
      $UserPath = $RootFolder + "\" + $DomainUser.SamAccountName
      $AllowUser = $DomainBios + "\" + $DomainUser.SamAccountName
      $UserRuleSet = (
         $AllowUser,
         [System.Security.AccessControl.FileSystemRights]::Modify,
         ([System.Security.AccessControl.InheritanceFlags]::ObjectInherit -bor [System.Security.AccessControl.InheritanceFlags]::ContainerInherit),
         [System.Security.AccessControl.PropagationFlags]::None,
         [System.Security.AccessControl.AccessControlType]::Allow
      )
      $UserAcl = New-Object System.Security.AccessControl.FileSystemAccessRule $UserRuleSet

      Write-Output "Create Folder : `"$UserPath`""
      New-Item -Path $UserPath -ItemType Directory
      $FolderAcl = Get-Acl $UserPath
      $FolderAcl.SetAccessRule($UserAcl)
      $FolderAcl | Set-Acl $UserPath
   }
}
exit