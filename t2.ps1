[CmdletBinding()]
param(
    [string]$ComputerName,
    [pscredential]$Credential,
    [switch]$UseLibrary
)

if ($UseLibrary) {
    $man = [Dataplat.Dbatools.Connection.ManagementConnection]::new( $ComputerName )
    $man.AddGoodCredential( $Credential)
    $cmParam = [DbaCmConnectionParameter]::new( $man )
    $obj = $cmParam.Connection.QueryCimRMInstance( $Credential, "SELECT * FROM Win32_Service WHERE name = 'SQLSERVERAGENT'" )
    $obj | icim -MethodName StopService
} else {
    $obj = Get-DbaCmObject -ComputerName $ComputerName -Namespace "root\cimv2" -query "SELECT * FROM Win32_Service WHERE name = 'SQLSERVERAGENT'" -Credential $Credential
    $obj | icim -me StopService
}
