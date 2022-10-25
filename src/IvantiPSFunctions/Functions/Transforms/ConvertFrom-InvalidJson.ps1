function ConvertFrom-InvalidJson {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [string]$responseString
    )
    # This grabs two single or double quote characters that are consecutive that are followed by any amount of whitespace
    # and a single colon. I think that's defines all JSON keys.
    $find = @'
("{2}|'{2})\s*:
'@
    $replace = @'
    "NullKey":
'@
    # Replace with literal value of "NULL" for now in case we want to use it we can search for that instead of an empty string
    # Could also remove the whole line by adding ^ to the beginning of $find and .* to the end, and replacing with ''
    $emptyKeysRemoved = $responseString -replace $find, $replace
    # Converts the fixed json string into the object we are already looking for in other functions
    return $emptyKeysRemoved | ConvertFrom-Json
}