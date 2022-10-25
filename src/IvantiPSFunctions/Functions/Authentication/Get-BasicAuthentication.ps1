#Function used to encode creds to Base64 for use in basic authenication
function Get-BasicAuthentication {
    param (
        $Username,
        $Password
    )
    try {
        $Encoded = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${Username}:$Password"))
    }
    catch {
        $LogMessage = "Unable to encode credentials $Username : $Password"
        Write-Error -Message $LogMessage -ErrorAction Stop
    }    
    return $Encoded
}