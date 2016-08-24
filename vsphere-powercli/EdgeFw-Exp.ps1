Param (
   [Parameter(Mandatory = $True, HelpMessage="CSV File Path")][alias("-file","f")][ValidateNotNullOrEmpty()][string]$FilePath,
   [Parameter(Mandatory = $True, HelpMessage="Edge Gateway Name")][alias("-gateway","g")][ValidateNotNullOrEmpty()][string]$EdgeName,
   [alias("-export","e")][switch]$ExportFlag,
   [alias("-import","i")][switch]$ImportFlag
)
if ($ExportFlag -and $ImportFlag) {
   echo "`"export`"‚Æ`"import`"‚Í”r‘¼"
   exit 255
}
 
# vCloud Director
$VcdSv = "vcd.sample.local"
$VcdUser = "Administrator"
$VcdPass = "Password"
 
# Snap-in / Connect to vCD
Add-PSSnapin VMware.VimAutomation.Core
Add-PSSnapin Vmware.VimAutomation.Cloud
Connect-CIServer -Server $VcdSv -User $VcdUser -Password $VcdPass
try {
   $EdgeView = Search-Cloud -QueryType EdgeGateway -Name $EdgeName -ErrorAction Stop | Get-CIView
} catch {
   exit 1
}
 
if ($ExportFlag) {
   $WebClient = New-Object System.Net.WebClient
   $WebClient.Headers.Add("x-vcloud-authorization",$EdgeView.Client.SessionKey)
   $WebClient.Headers.Add("accept",$EdgeView.Type + ";version=5.1")
   [XML]$EdgeConfXml = $WebClient.DownloadString($EdgeView.href)
   $EdgeFwRules = $EdgeConfXml.EdgeGateway.Configuration.EdgegatewayServiceConfiguration.FirewallService.FirewallRule
 
   $RuleArray = @()
   if ($EdgeFwRules) {
      $EdgeFwRules | Foreach-Object {
         if ($_.Protocols.Any) {
            $Protocols = "Any"
         } elseif ($_.Protocols.Tcp) {
            $Protocols = "TCP"
         } elseif ($_.Protocols.Udp) {
            $Protocols = "UDP"
         } elseif ($_.Protocols.Icmp) {
            $Protocols = "ICMP"
         } else {
            $Protocols = "Any"
         }
         $NewRule = New-Object PSObject -Property @{
            ID = $_.Id
            IsEnabled = $_.IsEnabled
            Description = $_.Description
            Policy = $_.Policy
            Protocols = $Protocols
            SourceIp = $_.SourceIp
            SourcePortRange = $_.SourcePortRange
            DestinationIp = $_.DestinationIp
            DestinationPortRange = $_.DestinationPortRange
            MatchOnTranslate = $_.MatchOnTranslate
            EnableLogging = $_.EnableLogging
         }
         $RuleArray += $NewRule
      }
   }
   $RuleArray | Export-Csv -Path $FilePath -NoType
}
 
if ($ImportFlag) {
   $FwService = New-Object VMware.VimAutomation.Cloud.Views.FirewallService
   $FwService.DefaultAction = "drop"
   $FwService.LogDefaultAction = $False
   $FwService.IsEnabled = $True
   $FwService.FirewallRule = @()
    
   Import-Csv -path $FilePath | Foreach-Object {
      $Rule = $_
      $FwService.FirewallRule += New-Object VMware.VimAutomation.Cloud.Views.FirewallRule
      $Row = $Rule.ID - 1 -as [int]
       
      $FwService.FirewallRule[$Row].Description = $Rule.Description
      $FwService.FirewallRule[$Row].Policy = $Rule.Policy
      $FwService.FirewallRule[$Row].SourceIp = $Rule.SourceIp
      $FwService.FirewallRule[$Row].DestinationIp = $Rule.DestinationIp
       
      if ($Rule.IsEnabled -eq "TRUE") {
         $FwService.FirewallRule[$Row].IsEnabled = $True
      } else {
         $FwService.FirewallRule[$Row].IsEnabled = $False
      }
      if ($Rule.MatchOnTranslate -eq "TRUE") {
         $FwService.FirewallRule[$Row].MatchOnTranslate = $True
      } else {
         $FwService.FirewallRule[$Row].MatchOnTranslate = $False
      }
      if ($Rule.EnableLogging -eq "TRUE") {
         $FwService.FirewallRule[$Row].EnableLogging = $True
      } else {
         $FwService.FirewallRule[$Row].EnableLogging = $False
      }
       
      $FwService.FirewallRule[$Row].Protocols = New-Object VMware.VimAutomation.Cloud.Views.FirewallRuleTypeProtocols
      switch ($Rule.Protocols) {
         "Any" {
            $FwService.FirewallRule[$Row].Protocols.Any = $True
            $FwService.FirewallRule[$Row].SourcePortRange = $Rule.SourcePortRange
            $FwService.FirewallRule[$Row].DestinationPortRange = $Rule.DestinationPortRange
         }
         "TCP" {
            $FwService.FirewallRule[$Row].Protocols.Tcp = $True
            $FwService.FirewallRule[$Row].SourcePortRange = $Rule.SourcePortRange
            $FwService.FirewallRule[$Row].DestinationPortRange = $Rule.DestinationPortRange
         }
         "UDP" {
            $FwService.FirewallRule[$Row].Protocols.Udp = $True
            $FwService.FirewallRule[$Row].SourcePortRange = $Rule.SourcePortRange
            $FwService.FirewallRule[$Row].DestinationPortRange = $Rule.DestinationPortRange
         }
         "ICMP" {
            $FwService.FirewallRule[$Row].Protocols.Icmp = $True
         }
      }
   }
   $EdgeView.ConfigureServices($FwService)
}
Disconnect-CIServer
exit
