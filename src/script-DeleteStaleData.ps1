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
$_daysAgo = (Get-Date).AddDays(-90)
$_date = Get-Date -Date $_daysAgo -Format 'yyyy-MM-dd'
$_ignoreWarrantyProviders = $true
$_dataEndpoints = "device","data"

#Run Code
foreach ( $_endpoint in $_dataEndpoints ) {

    #Get list of providers
    try {

        [System.Collections.ArrayList]$_providers = @(Invoke-Command -ScriptBlock {

            Get-NeuronsDataProviders -Landscape $_landscape -DataEndpoint $_endpoint -Token $_userJWT
            $_dbgMessage = "Got list of providers for $_endpoint endpoint"
            Write-Host $_dbgMessage

        })

        if ( $_ignoreWarrantyProviders -eq $true ) {
            $_providers.Remove("dellwarrantycollector")
            $_providers.Remove("lenovowarrantycollector")
        }

    } catch {

        Throw "Couldn't get list of providers for $_endpoint endpoint"

    }

    foreach ( $_provider in $_providers ) {
        
        # ----- Delete data for specific provider -----
        $_filter = "_provider eq '$_provider' and DiscoveryMetadata.DiscoveryServiceLastUpdateTime le '$_date'&`$providerFilter=$_provider"
        $_deviceIds = $null
        $_deviceIds = Get-NeuronsData -Landscape $_landscape -DataEndpoint $_endpoint -FilterString $_filter -Token $_userJWT

        if ($_deviceIds) {

            $_dbgMessage = ""+$_deviceIds.Length+" total records to delete for: Provider=$_provider, Endpoint=$_endpoint"
            Write-Host $_dbgMessage

            $_result = Invoke-Command -ScriptBlock {
                Invoke-DeletePartialProviderData -Landscape $_landscape -DataEndpoint $_endpoint -Provider $_provider -DiscoveryIds $_deviceIds -Token $_userJWT
            }

            if ( !$_result ) {
                $_dbgMessage = "Successfully submitted delete requests for: Provider=$_provider, Endpoint=$_endpoint"
                Write-Host $_dbgMessage
            } else {
                $_dbgMessage = "Unable to delete records for: Provider=$_provider, Endpoint=$_endpoint"
                Write-Host $_dbgMessage
            }
            
        } else {
            $_dbgMessage = "No records to delete for: Provider=$_provider, Endpoint=$_endpoint"
            Write-Host $_dbgMessage
        }
    }

}