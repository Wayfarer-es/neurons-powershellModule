#Import Module
if (Test-Path ".\IvantiPSFunctions\IvantiPSFunctions.psm1" -PathType leaf) {
    $Module = Get-Item ".\IvantiPSFunctions\IvantiPSFunctions.psm1" | Resolve-Path -Relative
    Write-Debug "Found module file"
} elseif (Test-Path ".\src\IvantiPSFunctions\IvantiPSFunctions.psm1" -PathType leaf) {
    $Module = Get-Item ".\src\IvantiPSFunctions\IvantiPSFunctions.psm1" | Resolve-Path -Relative
    Write-Debug "Found module file"
} else {
    throw "PowerShell module cannot be found."
    Exit
}
Import-Module -Name $Module -ArgumentList $DevMode -Force

#Import environment
$_environmentConfig = Get-Content -Path "$PSScriptRoot\Environment\environment-config.json" | ConvertFrom-Json
$_environment = $_environmentConfig.($_environmentConfig.default)  

#Set parameters to run
$_NeuronsURL = $_environment.tenant_url
$_user = $_environment.user
$_password = $_environment.password
$_landscape = $_environment.landscape
$_userJWT = Get-UserJwt -NeuronsURL $_NeuronsURL -User $_user -Password $_password

# *************** Parameters to modify for script to run ***************
$_connectorID = "00ce1ae6-cdab-41ad-b4a3-3db48e8f7789"
$_provider = "DellWarrantyCollector"
$_dataEndpoints = "device","data"
$_filter = "DiscoveryMetadata.Connectors.ConnectorId eq '$_connectorID'"

#Run code
foreach ($_endpoint in $_dataEndpoints) {

    
    $_deviceIds = Get-NeuronsData -Landscape $_landscape -DataEndpoint $_endpoint -FilterString $_filter -Token $_userJWT

    if ($null -ne $_deviceIds -or $_deviceIds) {

        $_dbgMessage = "Total records to delete - "+$_deviceIds.Length
        Write-Host $_dbgMessage

        $_result = Invoke-Command -ScriptBlock {
            Invoke-DeletePartialProviderData -Landscape $_landscape -DataEndpoint $_endpoint -Provider $_provider -DiscoveryIds $_deviceIds -Token $_userJWT
        }

        if ( !$_result ) {
            $_dbgMessage = "Successfully submitted delete requests for Connector: $_connectorID for $_endpoint endpoint"
            Write-Host $_dbgMessage
        } else {
            $_dbgMessage = "Unable to delete records for Connector: $_connectorID for $_endpoint endpoint"
            Write-Host $_dbgMessage
        }
        
    } else {
        $_dbgMessage = "No records to delete for $_endpoint endpoint"
        Write-Host $_dbgMessage
    }

}