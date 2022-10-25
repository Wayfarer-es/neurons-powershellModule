<#
    .SYNOPSIS
    Use this function to invoke rest method to an API endpoint that utilizes rate limiting.

    .DESCRIPTION
    Invoking a GET http request to API endpoint and returning JSON data, retrying if the rate limit is hit.

    .PARAMETER Uri
    Mandatory. Uri of the API endpoint to invoke GET method.

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>
function Get-APIDataWithRateLimits {
    [cmdletbinding()]
    param (
        [object]$Header,
        [string]$Uri,
        [string]$Method,
        [Parameter(Mandatory = $false)][string]$Body,
        [Parameter(Mandatory = $false)][string]$SkipCertificate
    )   
    try {
        if ($SkipCertificate -ne "true") {
            $searchResult = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Header -Body $Body
        }
        else {
            $searchResult = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Header -Body $Body -SkipCertificateCheck
        }     
    } 
    catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 429) {
            $retryAfter = $_.Exception.Response.Headers.RetryAfter
            $retryCount = 0
            do {
                $newStatus = $null
                Write-Debug -message "Reached API rate limit. Retrying in $retryAfter seconds..."
                Start-Sleep -s $retryAfter
                try {
                    if ($SkipCertificate -ne "true") {
                        $searchResult = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Header -Body $Body
                    }
                    else {
                        $searchResult = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Header -Body $Body -SkipCertificateCheck
                    } 
                }
                catch {
                    $newStatus = $($_.Exception.Response.StatusCode.value__)
                }
                $retryCount++
            } until (!$newStatus -or $retryCount -eq 5)
            if ($retryCount -ge 5) {
                $logMessage = "Reached the maximum number of retry attempts."
                Write-Debug -message $logMessage -ErrorAction Stop
            } 
        }
        else {
            $StatusCode = [string]$($_.Exception.Response.StatusCode.value__)
            $ExceptionVariable = $_.Exception.Message
            $ErrorDetail = $_.ErrorDetails
            if (!$StatusCode -and $_.Exception.StatusCode) {
                $StatusCode = [string]$_.Exception.StatusCode
            }
            elseif (!$StatusCode -and $ErrorDetail.Message -match "{") {
                $ErrorObject = $ErrorDetail | ConvertFrom-Json
                $StatusCode = [string]$ErrorObject.status
                if([string]::IsNullOrEmpty($ExceptionVariable) -and $ErrorObject.message){
                    $ExceptionVariable = [Exception]::new("$($ErrorObject.message)") 
                }     
            }
            if([string]::IsNullOrEmpty($ExceptionVariable)){
                $ExceptionVariable = [Exception]::new("Unable to find request site Http Error code: $($StatusCode)")
            }    
            $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                $ExceptionVariable,
                "$($StatusCode)",
                [System.Management.Automation.ErrorCategory]::ConnectionError,
                $_.TargetObject
            )
            $ErrorRecord.ErrorDetails = $ErrorDetail
            $PSCmdlet.WriteError($ErrorRecord)
            return $ExceptionVariable
            break
        }   
    } 
    return $searchResult
}
