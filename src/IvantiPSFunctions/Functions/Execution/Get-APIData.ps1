<#
    .SYNOPSIS
    Use this function to invoke rest method to an API endpoint.

    .DESCRIPTION
    Invoking a GET http request to API endpoint and returning JSON data

    .PARAMETER Uri
    Mandatory. Uri of the API endpoint to invoke GET method.

    .NOTES
    Author:  Ivanti
    Version: 1.1
#>
function Get-APIData {
    [cmdletbinding()]
    param (
        [object]$Header,
        [string]$Uri,
        [Parameter(Mandatory = $false)][string]$SkipCertificate,
        [Parameter(Mandatory = $false)][string]$Body,
        [Parameter(Mandatory = $false)][string]$Method = "GET",
        [Parameter(Mandatory = $false)][string]$ErrorActionContinue = "false"
    )   
       
    try {
        if($Body){
            if ($SkipCertificate -ne "true") {
                $searchResult = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Header -Body $Body
            }
            else {
                $searchResult = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Header -Body $Body -SkipCertificateCheck
            }     
        }
        else{
            if ($SkipCertificate -ne "true") {
                $searchResult = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Header
            }
            else {
                $searchResult = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Header -SkipCertificateCheck
            }     
        }
   
    } 
    catch {    
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
        if ($ErrorActionContinue -ne "true") {
            break
        }
    } 
    return $searchResult
}
