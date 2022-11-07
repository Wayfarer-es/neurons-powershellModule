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

# ----- Set Parameters ----- 

#Set parameters to run
$_clientID = "[insert client id here]"
$_clientSecret = "[insert client secret here]"
$_authURL = "[insert auth URL here]"
$_scope = "dataservices.read"

#Use these
$_userJWT = ''
$_landscape = "NVU"
$_connectorServerName = "uemserver"


#Static script parameters
$_dataEndpoints = "device","data"

# ----- Run Code ----- 
if ( $_userJWT) { $_token = $_userJWT } else { $_token = Get-AccessToken -AuthURL $_authURL -ClientID $_clientID -ClientSecret $_clientSecret -Scopes $_scope }

try {
    $_response = Invoke-Command -ScriptBlock {
        Get-NeuronsConnectorServerConnectors -Landscape $_landscape -ConnectorServerName $_connectorServerName -Token $_token
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
        $_deviceIds = Get-NeuronsData -Landscape $_landscape -DataEndpoint $_endpoint -FilterString $_filter -Token $_token

        if ($_deviceIds) {

            $_dbgMessage = ""+$_deviceIds.Length+" total records to delete for: Connector=$_connectorID, Provider=$_provider, Endpoint=$_endpoint"
            Write-Host $_dbgMessage

            $_result = Invoke-Command -ScriptBlock {
                Invoke-DeletePartialProviderData -Landscape $_landscape -DataEndpoint $_endpoint -Provider $_provider -DiscoveryIds $_deviceIds -Token $_token
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
