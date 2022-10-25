<#
    .SYNOPSIS
    Use this function to build out the header for Basic Authentication.

    .DESCRIPTION
    Creating Header Dictionary
    .PARAMETER AuthorizationString
    Mandatory. AuthorizationString is formatted as "Username:Password"

    .NOTES
    Author:  Ivanti
    Version: 1.1
#>
function Get-Header {
    [cmdletbinding()]
    param (
        $AuthorizationString,
        [Parameter(Mandatory = $false)][Bool]$Bearer = $false,
        [Parameter(Mandatory = $false)][string]$ContentType = "application/json",
        [Parameter(Mandatory = $false)][string]$GrantType,
        [Parameter(Mandatory = $false)][string]$Accept
    )    
    try {

        $header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        if ($Bearer) {
            $header.Add("Authorization", "Bearer $AuthorizationString")
        }
        else {
            $header.Add("Authorization", "Basic $AuthorizationString")
        }
        switch ($Accept) {
            "json" {
                $header.Add("Accept", "application/json")
            }
        } 
        switch ($GrantType) {
            "client_credentials" {
                $header.Add("grant_type", "client_credentials")
            }
        } 
        switch ($ContentType) {
            "application/json" {
                $header.Add("Content-Type", "application/json")
            }
            "application/xml" {
                $header.Add("Content-Type", "application/xml")
            }
            "x-www-form-urlencoded" {
                $header.Add("Content-Type", "application/x-www-form-urlencoded")
            }

        }
    }
    catch {
        $Exception = [Exception]::new("Unable to generate header")
        Write-Error -message $Exception -ErrorAction Stop
    } 
    return $header
}