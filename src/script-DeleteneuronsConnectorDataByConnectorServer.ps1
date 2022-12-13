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
$_connectorServerName = "uemserver"
$_dataEndpoints = "device","data"
$_filter = "DiscoveryMetadata.Connectors.ConnectorId eq '$_connectorID'"

#Run Code 
try {
    $_response = Invoke-Command -ScriptBlock {
        Get-NeuronsConnectorServerConnectors -Landscape $_landscape -ConnectorServerName $_connectorServerName -Token $_userJWT
    }
} catch {
    Throw "Couldn't get connectors from connector server"
}

foreach ( $_connector in $_response.value ) {

    $_connectorID = $_connector.RecId
    $_provider = Invoke-Command -ScriptBlock {
        Get-NeuronsConnectorProviderByConfigTypeRecID -ConfigurationTypeRecID $_connector.ConfigurationTypeRecId
    }

    foreach ( $_endpoint in $_dataEndpoints ) {

        $_filter = "DiscoveryMetadata.Connectors.ConnectorId eq '$_connectorID'"
        $_deviceIds = $null
        $_deviceIds = Get-NeuronsData -Landscape $_landscape -DataEndpoint $_endpoint -FilterString $_filter -Token $_userJWT

        if ($_deviceIds) {

            $_dbgMessage = ""+$_deviceIds.Length+" total records to delete for: Connector=$_connectorID, Provider=$_provider, Endpoint=$_endpoint"
            Write-Host $_dbgMessage

            $_result = Invoke-Command -ScriptBlock {
                Invoke-DeletePartialProviderData -Landscape $_landscape -DataEndpoint $_endpoint -Provider $_provider -DiscoveryIds $_deviceIds -Token $_userJWT
            }

            if ( !$_result ) {
                $_dbgMessage = "Successfully submitted delete requests for: Connector=$_connectorID, Provider=$_provider, Endpoint=$_endpoint"
                Write-Host $_dbgMessage
            } else {
                $_dbgMessage = "Unable to delete records for: Connector=$_connectorID, Provider=$_provider, Endpoint=$_endpoint"
                Write-Host $_dbgMessage
            }
            
        } else {
            $_dbgMessage = "No records to delete for: Connector=$_connectorID, Provider=$_provider, Endpoint=$_endpoint"
            Write-Host $_dbgMessage
        }

    }

}
