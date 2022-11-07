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
$_userJWT = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjA3NDNBNjJGQzgzMUQ5RDU2MUQzOEM4MzM4QkYxMkNFNDkzQ0M2MzEiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJCME9tTDhneDJkVmgwNHlET0w4U3prazh4akUifQ.eyJuYmYiOjE2NjY3MTIwNDMsImV4cCI6MTY2NjcxNTY0MywiaXNzIjoiaHR0cHM6Ly9udnVwcmQtc2ZjLml2YW50aWNsb3VkLmNvbS92YW50b3NpLml2YW50aWNsb3VkLmNvbSIsImF1ZCI6Imh0dHBzOi8vbnZ1cHJkLXNmYy5pdmFudGljbG91ZC5jb20vdmFudG9zaS5pdmFudGljbG91ZC5jb20vcmVzb3VyY2VzIiwiY2xpZW50X2lkIjoiVW5vV2ViQ2xpZW50SWQiLCJzdWIiOiIyOTFiMDhhMy02MjU4LTQxNDItOTJlNS0wOTE5NmU4NWJjZjYiLCJhdXRoX3RpbWUiOjE2NjY3MTIwNDMsImlkcCI6ImxvY2FsIiwiZ2l2ZW5fbmFtZSI6IlRvZGQiLCJmYW1pbHlfbmFtZSI6IkxhYnJ1bSAoSXZhbnRpKSIsImVtYWlsIjoidG9kZC5sYWJydW1AaXZhbnRpLmNvbSIsInByZWZlcnJlZF91c2VybmFtZSI6InRvZGQubGFicnVtQGl2YW50aS5jb20iLCJ0aWQiOiI1YzVhODFkNi1kZGY0LTQ2NzEtOWI4ZC0xMTI5MjM0NDM2ZjkiLCJVbm9UZW5hbnRJZCI6IjVjNWE4MWQ2LWRkZjQtNDY3MS05YjhkLTExMjkyMzQ0MzZmOSIsInNpZCI6Ijg1RTlFMkE0MkQyMDNGOEI4NkI0RTdGNTMzQ0YyNjczIiwiaWF0IjoxNjY2NzEyMDQzLCJzY29wZSI6WyJvcGVuaWQiLCJwcm9maWxlIiwiZW1haWwiLCJVbm8iXSwiYW1yIjpbInB3ZCJdfQ.eLNiXT6mxle29zfuxb0ThajW6oZpczgy0o2qTKYX2RKQdYXhm_GOHYCYVZVBRz3hPf-mPosZLK81gsD6fGieCZbQaokxIPlkD71CUHGu3YaUg-sMufi3XTxcFt2Ucft_urb24QF_5W39FQHtLYBQOrnSS3WROuYvOomRKfo7okjjVtPDRIrsVOhwqubf97VpN4SNR4JFwaTey7Zlty2IrGdCo60qVeYt3JWTedAEyhPoi2Ri3bSGdIyW1nWjsWr_PCFyRuoMYOa6C3snyNGOwH12KkyVJ5J5Hpm8Xn5SXz9j5Fh7HFJbDRjoLeh2_UDt2U1CWpNtiai5ms9AYBjO0Q'
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
                Invoke-DeleteNeuronsConnectorData -Landscape $_landscape -DataEndpoint $_endpoint -Provider $_provider -DiscoveryIds $_deviceIds -Token $_token
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