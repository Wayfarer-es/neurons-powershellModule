#Function to generate authorization token using client credentials.
function Get-ClientCredentialsAuthentication {
    param (
        $ClientID,
        $ClientSecret
    )

    #Method for decrypting a secure string differs between older and newer PS versions so logic is needed to check version and use appropriate method.
    try {
        $ClientSecretDecrypted = Decrypt-String -SecString $ClientSecret
    }
    catch {
        $logMessage = "Unable to decrypt $ClientSecret"
        Write-Error -Message $logMessage -ErrorAction Stop
    }

    #Build the request body and header. This will be done differently depending on the API's authorization method.
    $body = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $body.Add("grant_type", "client_credentials")
    $body.Add("client_id", $ClientID)
    $body.Add("client_secret", $ClientSecretDecrypted)

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Accept", "application/json")
    $headers.Add("Content-Type", "application/x-www-form-urlencoded")

    $uri = "https://sample.api/token"
    $token = Invoke-RestMethod -Uri $authUri -Method POST -Headers $header -Body $body 

    return $token.access_token
}