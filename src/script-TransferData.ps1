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
$_environmentToExportData = "vantosi"
$_environmentToImportData = "ux"

#Set Export Tenant Parameters
$_t1_clientID = $_environmentConfig.($_environmentToExportData).client_id
$_t1_clientSecret = $_environmentConfig.($_environmentToExportData).client_secret
$_t1_authURL = $_environmentConfig.($_environmentToExportData).auth_url
$_t1_scope = "dataservices.read"
$_t1_landscape = $_environmentConfig.($_environmentToExportData).landscape

#Set Import Tenant Parameters
$_t2_NeuronsURL = $_environmentConfig.($_environmentToImportData).tenant_url
$_t2_user = $_environmentConfig.($_environmentToImportData).user
$_t2_password = $_environmentConfig.($_environmentToImportData).password
$_t2_landscape = $_environmentConfig.($_environmentToImportData).landscape

# *************** Parameters to modify for script to run ***************
$_dataEndpoints = "device","data"

#Run code
$_t1_token = Get-AccessToken -AuthURL $_t1_authURL -ClientID $_t1_clientID -ClientSecret $_t1_clientSecret -Scopes $_t1_scope
$_t2_token = Get-UserJwt -NeuronsURL $_t2_NeuronsURL -User $_t2_user -Password $_t2_password

foreach ( $_endpoint in $_dataEndpoints ) {

    #Get list of providers
    try {
        [System.Collections.ArrayList]$_providers = @(Invoke-Command -ScriptBlock {
            Get-NeuronsDataProviders -Landscape $_t1_landscape -DataEndpoint $_endpoint -Token $_t1_token
            $_dbgMessage = "Got list of providers for $_endpoint endpoint"
            Write-Host $_dbgMessage
        })
    } catch {
        Throw "Couldn't get list of providers for $_endpoint endpoint"
    }

    #Get data for a provider
    foreach ( $_provider in $_providers ) {
        # ----- Check to see if JWT tokens need to be rereshed -----
        $_t1_token = Get-AccessToken -AuthURL $_t1_authURL -ClientID $_t1_clientID -ClientSecret $_t1_clientSecret -Scopes $_t1_scope -Token $_t1_token

        # ----- Get data for specific provider -----
        $_providerFilter = "_provider eq '$_provider' and exists(DiscoveryId)&`$providerFilter=$_provider"
        $_deviceIds = $null
        $_deviceIds = Get-NeuronsData -Landscape $_t1_landscape -DataEndpoint $_endpoint -FilterString $_providerFilter -Token $_t1_token

        $_dbgMessage = ""+$_deviceIds.Length+" total records to export for: Provider=$_provider, Endpoint=$_endpoint"
        Write-Host $_dbgMessage

        foreach ( $_deviceId in $_deviceIds ) {
            $_providerRecordFilter = "_provider eq '$_provider' and DiscoveryId eq '$_deviceId'&`$providerFilter=$_provider"

            $_exportResult = Invoke-Command -ScriptBlock {
                Get-NeuronsDataAll -Landscape $_t1_landscape -DataEndpoint $_endpoint -SaveToDevice $false -FilterString $_providerRecordFilter -DiscoveryId $_deviceId -CSVPath "$PSScriptRoot\Data\$_provider\" -Token $_t1_token
            }

            $_transformedResult = Invoke-Command -ScriptBlock {
                Invoke-PrepDemoRecord -Record $_exportResult.Record -DateRandomizer $false
            }

            $_importResult = Invoke-Command -ScriptBlock {
                # ----- Check to see if JWT tokens need to be rereshed -----
                $_t2_token = Get-UserJwt -NeuronsURL $_t2_NeuronsURL -User $_t2_user -Password $_t2_password -Token $_t2_token

                #Submit the data
                Invoke-SubmitNeuronsData -Record $_transformedResult -Landscape $_t2_landscape -DataEndpoint $_endpoint -Provider $_provider -Token $_t2_token
            }

            if ( $_importResult.Status = "200" ) {
                $_dbgMessage = "Success: Submitted record for Provider=$_provider, Endpoint=$_endpoint, DiscoveryId=$_deviceId"
                Write-Host $_dbgMessage
            } else {
                $_dbgMessage = "Failure: Failed to submit record for Provider=$_provider, Endpoint=$_endpoint, DiscoveryId=$_deviceId"
                Write-Error $_dbgMessage
            }
        }
    }
}
