# *************************** Import Ivanti Neurons PowerShell Module *************************** 
if (Test-Path ".\IvantiPSFunctions\IvantiPSFunctions.psm1" -PathType leaf) {
    $Module = Get-Item ".\IvantiPSFunctions\IvantiPSFunctions.psm1" | Resolve-Path -Relative
    Write-Debug "Found module file"
} elseif (Test-Path ".\src\IvantiPSFunctions\IvantiPSFunctions.psm1" -PathType leaf) {
    $Module = Get-Item ".\src\IvantiPSFunctions\IvantiPSFunctions.psm1" | Resolve-Path -Relative
    Write-Debug "Found module file"
} else {
    $StatusCode = "404"
    $Exception = [Exception]::new("PowerShell module cannot be found.  Error code ($($StatusCode))")
    $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
        $Exception,
        "$($StatusCode)",
        [System.Management.Automation.ErrorCategory]::FatalError,
        $TargetObject
    )
    $PSCmdlet.WriteError($ErrorRecord)
    Exit
}

# ----- Import Module ----- 
Import-Module -Name $Module -ArgumentList $DevMode -Force

# ************ Set Parameters ************ 

#Parameters to modify for script to run
$_userJWT = ''
$_landscape = "NVU"
$_daysAgo = (Get-Date).AddDays(-90)
$_date = Get-Date -Date $_daysAgo -Format 'yyyy-MM-dd'
$_ignoreWarrantyProviders = $true

#Static script parameters
$_dataEndpoints = "device","data"

# ************ Run Code ************ 
if ( $_userJWT) { $_token = $_userJWT } else { $_token = Get-AccessToken -AuthURL $_authURL -ClientID $_clientID -ClientSecret $_clientSecret -Scopes $_scope }

foreach ( $_endpoint in $_dataEndpoints ) {

    # ----- Get list of providers -----
    try {

        [System.Collections.ArrayList]$_providers = Invoke-Command -ScriptBlock {

            Get-NeuronsDataProviders -Landscape $_landscape -DataEndpoint $_endpoint -Token $_token
            $_dbgMessage = "Got list of providers for $_endpoint endpoint"
            Write-Host $_dbgMessage

        }

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
        $_deviceIds = Get-NeuronsData -Landscape $_landscape -DataEndpoint $_endpoint -FilterString $_filter -Token $_token

        if ($_deviceIds) {

            $_dbgMessage = ""+$_deviceIds.Length+" total records to delete for: Provider=$_provider, Endpoint=$_endpoint"
            Write-Host $_dbgMessage

            $_result = Invoke-Command -ScriptBlock {
                Invoke-DeletePartialProviderData -Landscape $_landscape -DataEndpoint $_endpoint -Provider $_provider -DiscoveryIds $_deviceIds -Token $_token
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