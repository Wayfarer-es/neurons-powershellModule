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

# ----- Check to see if Module is signed ----- 
if ($IsWindows) {
    $Signed = Get-AuthenticodeSignature -FilePath $Module
    if ($DevMode -ne "true" -and $Signed.Status -ne "Valid") {
        Write-Error "Module is not signed."
        Exit
    }
}
else {
    Write-Debug "Skipping module certificate check."
}

# ----- Import Module ----- 
Import-Module -Name $Module -ArgumentList $DevMode -Force

#Set parameters to run
$_clientID = "[insert client id here]"
$_clientSecret = "[insert client secret here]"
$_authURL = "[insert auth URL here]"
$_scope = "dataservices.read"

#Use these
$_userJWT = '[insert user JWT here]'
$_landscape = "NVU"
$_connectorID = "00ce1ae6-cdab-41ad-b4a3-3db48e8f7789"
$_provider = "DellWarrantyCollector"

#Static script parameters
$_dataEndpoints = "device","data"
$_filter = "DiscoveryMetadata.Connectors.ConnectorId eq '$_connectorID'"

#Run code
foreach ($_endpoint in $_dataEndpoints) {

    if ( $_userJWT) { $_token = $_userJWT } else { $_token = Get-AccessToken -AuthURL $_authURL -ClientID $_clientID -ClientSecret $_clientSecret -Scopes $_scope }
    $_deviceIds = Get-NeuronsData -Landscape $_landscape -DataEndpoint $_endpoint -FilterString $_filter -Token $_token

    if ($null -ne $_deviceIds -or $_deviceIds) {

        $_dbgMessage = "Total records to delete - "+$_deviceIds.Length
        Write-Host $_dbgMessage

        $_result = Invoke-Command -ScriptBlock {
            Invoke-DeleteNeuronsConnectorData -Landscape $_landscape -DataEndpoint $_endpoint -Provider $_provider -DiscoveryIds $_deviceIds -Token $_token
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