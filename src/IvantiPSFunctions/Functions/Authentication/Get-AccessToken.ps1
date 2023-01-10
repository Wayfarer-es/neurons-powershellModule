 <#
    .SYNOPSIS
    Run to get an Access token via client credentials OAuth 2 flow.

    .DESCRIPTION
    Run to get a JWT token via client credentials OAuth 2 flow.

    .PARAMETER AuthURL
    Mandatory. The URL to the authentication server.
    
    .PARAMETER ClientID
    Mandatory. The client identifier issues during the app registration process.
    
    .PARAMETER ClientSecret
    Mandatory. The client secret issues during the app registration process.

    .PARAMETER Scopes
    Mandatory. The scope of the access request.

    .PARAMETER Token
    Optional. An existing token to check if it needs to be refreshed.

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

#Function to generate authorization token using client credentials.
function Get-AccessToken {
    param (

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$AuthURL,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$ClientID,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$ClientSecret,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$Scopes,

        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$Token   

    )


    if ( $Token ) {

        $_tokenDetails = Invoke-ParseJWTToken -Token $Token
        $_dateTimeNow = Get-Date
        $_dateTimeNowEpoch = Get-Date $_dateTimeNow -Uformat %s

        if ( ($_tokenDetails.exp - $_dateTimeNowEpoch) -gt 600) {
            return $Token
        } 

    }

    #Build the request body and header. This will be done differently depending on the API's authorization method.
    $_body = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $_body.Add("grant_type", "client_credentials")
    $_body.Add("client_id", $ClientID)
    $_body.Add("client_secret", $ClientSecret)
    $_body.Add("scope", $Scopes)

    $_headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $_headers.Add("Accept", "application/json")
    $_headers.Add("Content-Type", "application/x-www-form-urlencoded")

    $_token = Invoke-RestMethod -Uri $AuthURL -Method POST -Headers $_headers -Body $_body 

    return $_token.access_token
}