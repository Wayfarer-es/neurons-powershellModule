function Update-Date {
    [CmdletBinding()]
    param (
        [string]$dateString
    )
    if ([string]::IsNullOrEmpty($dateString)) {
        $date = $null
        $logMessage ="Update-Date module function cannot convert date to UTC since date is null"
        Write-Debug -Message $logMessage -ErrorAction Continue
    }
    else {
        try {
        [datetime]$dateObject = $dateString
        $date = $dateObject.ToString("yyyy-MM-ddTHH\:mm\:ss.fff\Z")
        }
        catch {
            $logMessage = "Unable to Convert this date to UTC: $($dateString)"
            Write-Debug -Message $logMessage -ErrorAction Continue
        }
    }
    return $date
}