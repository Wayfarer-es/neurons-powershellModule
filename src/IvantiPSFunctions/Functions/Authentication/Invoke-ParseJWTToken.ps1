 <#
    .SYNOPSIS
    Run to get the details of a JWT token.

    .DESCRIPTION
    Run to get the details of a JWT token.

    .PARAMETER Token
    Mandatory. A JWT token to decode.

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

#Function to parse JWT tokens
function Invoke-ParseJWTToken {
 
    param (

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$Token

    )
 
    #Validate as per https://tools.ietf.org/html/rfc7519
    #Access and ID Tokens are fine, Refresh Tokens will not work
    if (!$Token.Contains(".") -or !$Token.StartsWith("eyJ")) { Write-Error "Invalid Token" -ErrorAction Stop }
 
    #Header
    $Tokenheader = $Token.Split(".")[0].Replace('-', '+').Replace('_', '/')
    #Fix padding as needed, keep adding "=" until string length modulus 4 reaches 0
    while ($Tokenheader.Length % 4) { Write-Verbose "Invalid length for a Base-64 char array or string, adding ="; $Tokenheader += "=" }
    Write-Verbose "Base64 encoded (padded) header:"
    Write-Verbose $Tokenheader
    #Convert from Base64 encoded string to PSObject all at once
    Write-Verbose "Decoded header:"
    [System.Text.Encoding]::ASCII.GetString([system.convert]::FromBase64String($Tokenheader)) | ConvertFrom-Json | fl
 
    #Payload
    $TokenPayload = $Token.Split(".")[1].Replace('-', '+').Replace('_', '/')
    #Fix padding as needed, keep adding "=" until string length modulus 4 reaches 0
    while ($TokenPayload.Length % 4) { Write-Verbose "Invalid length for a Base-64 char array or string, adding ="; $TokenPayload += "=" }
    Write-Verbose "Base64 encoded (padded) payoad:"
    Write-Verbose $TokenPayload
    #Convert to Byte array
    $TokenByteArray = [System.Convert]::FromBase64String($TokenPayload)
    #Convert to string array
    $TokenArray = [System.Text.Encoding]::ASCII.GetString($TokenByteArray)
    Write-Verbose "Decoded array in JSON format:"
    Write-Verbose $TokenArray
    #Convert from JSON to PSObject
    $tokobj = $TokenArray | ConvertFrom-Json
    Write-Verbose "Decoded Payload:"
    
    return $tokobj
}