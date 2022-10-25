 <#
    .SYNOPSIS
    Run to decrypt a secure string.

    .DESCRIPTION
    Decrypts and returns PowerShell secure strings.

    .PARAMETER SecString
    Mandatory. The secure string that will be decrypted.

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

#Function to decrecypt secure strings
function Get-DecryptString {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [SecureString]$SecString
    )

    try {
        $DecryptedString = ConvertFrom-SecureString $SecString -AsPlainText
    }
    catch {
        $logMessage = "Unable to decrypt $SecString"
        Write-Error -Message $logMessage -ErrorAction Stop
        $DecryptedString = $null
    }
    return $DecryptedString
}