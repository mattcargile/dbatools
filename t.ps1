[CmdletBinding()]
param(
    [string]$ComputerName,
    [pscredential]$Credential,
    [switch]$UseLibrary,
    [switch]$UsePrivate
)

if ($UseLibrary) {
    $man = [Dataplat.Dbatools.Connection.ManagementConnection]::new( $ComputerName )
    $man.AddGoodCredential( $Credential)
    $cmParam = [DbaCmConnectionParameter]::new( $man )
    $obj = $cmParam.Connection.QueryCimRMInstance( $Credential, "SELECT * FROM Win32_Service WHERE name = 'MSSQLSERVER'" )
} else {
    $obj = Get-DbaCmObject -ComputerName $ComputerName -Namespace "root\cimv2" -query "SELECT * FROM Win32_Service WHERE name = 'MSSQLSERVER'" -Credential $Credential
}
$cimSvcObj = [pscustomobject]@{ Key = 'Value'; obj = $obj }
$temp = $cimSvcObj

$sbp = {
    if ( $null -eq $_.obj ) { 'It Failed' }
    else { 'It Worked'; $_.obj }
}
if ($UsePrivate) {
    $temp | Invoke-Parallel -ScriptBlock $sbp -Throttle 50 -ImportVariables
} else {
    $sbp = $ExecutionContext.InvokeCommand.NewScriptBlock("param(`$_)`r`n$($sbp.ToString())")
    $pwsh = [powershell]::Create().AddScript( $sbp ).AddArgument( $temp )
    $beginInvoke = $pwsh.BeginInvoke()
    $pwsh.EndInvoke( $beginInvoke)
    $pwsh.Dispose()
    $pwsh = $null
    $beginInvoke = $null
}
