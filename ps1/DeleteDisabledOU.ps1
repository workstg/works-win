$BaseOu = "OU=Root Div,DC=example,DC=local"
 
$ChildOus = Get-ADOrganizationalUnit -Filter "*" -SearchBase $BaseOu -SearchScope Subtree
:outer foreach ($ChildOu in $ChildOus) {
   if ($ChildOu.Name -eq "Root Div") {continue}
   if ($ChildOu.Name -eq "Exclude Div") {continue}
    
   $OuUsers = Get-ADUser -Filter "*" -SearchBase $ChildOu.DistinguishedName
   foreach ($OuUser in $OuUsers) {
      if ($OuUser.Enabled) {
         continue outer
      }
   }
   $OuUsers | Remove-ADUser -Confirm:$false
    
   Set-ADOrganizationalUnit -Identity $ChildOu.DistinguishedName -ProtectedFromAccidentalDeletion $false
   Remove-ADOrganizationalUnit -Identity $ChildOu.DistinguishedName
-Confirm:$false
}
 
exit
