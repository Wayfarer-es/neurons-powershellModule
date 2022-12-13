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
$_environmentToExportData = $_environmentConfig.($_environmentConfig.tenantToExportData)  
$_environmentToImportData = $_environmentConfig.($_environmentConfig.tenantToImportData)  

#Set Export Tenant Parameters
$_t1_clientID = $_environmentToExportData.client_id
$_t1_clientSecret = $_environmentToExportData.client_secret
$_t1_authURL = $_environmentToExportData.auth_url
$_t1_scope = "dataservices.read"
$_t1_landscape = $_environmentToExportData.landscape

#Set Import Tenant Parameters
$_t2_NeuronsURL = $_environment.tenant_url
$_t2_user = $_environment.user
$_t2_password = $_environment.password

# *************** Parameters to modify for script to run ***************
$_dataEndpoints = "device","data"

#Run code
$_t1_token = Get-AccessToken -AuthURL $_t1_authURL -ClientID $_t1_clientID -ClientSecret $_t1_clientSecret -Scopes $_t1_scope


foreach ( $_endpoint in $_dataEndpoints ) {

    #Get list of providers
    try {
        [System.Collections.ArrayList]$_providers = Invoke-Command -ScriptBlock {
            Get-NeuronsDataProviders -Landscape $_t1_landscape -DataEndpoint $_endpoint -Token $_t1_token
            $_dbgMessage = "Got list of providers for $_endpoint endpoint"
            Write-Host $_dbgMessage
        }
    } catch {
        Throw "Couldn't get list of providers for $_endpoint endpoint"
    }

    #Get data for a provider
    foreach ( $_provider in $_providers ) {
        # ----- Get data for specific provider -----
        $_providerFilter = "_provider eq '$_provider' and exists(DiscoveryId)&`$providerFilter=$_provider"
        $_deviceIds = $null
        $_deviceIds = Get-NeuronsData -Landscape $_t1_landscape -DataEndpoint $_endpoint -FilterString $_providerFilter -Token $_t1_token

        $_dbgMessage = ""+$_deviceIds.Length+" total records to export for: Provider=$_provider, Endpoint=$_endpoint"
        Write-Host $_dbgMessage

        foreach ( $_deviceId in $_deviceIds ) {
            $_providerRecordFilter = "_provider eq '$_provider' and DiscoveryId eq '$_deviceId'&`$providerFilter=$_provider"
            $_result = Invoke-Command -ScriptBlock {
                Get-NeuronsDataAll -Landscape $_t1_landscape -DataEndpoint $_endpoint -FilterString $_providerRecordFilter -DiscoveryId $_deviceId -CSVPath "$PSScriptRoot\Data\$_provider\" -Token $_t1_token
            }
            if ( $_result ) {
                $_dbgMessage = "Exported record for Provider=$_provider, Endpoint=$_endpoint, DiscoveryId=$_deviceId"
                Write-Host $_dbgMessage
            }
        }

            
    }

}
