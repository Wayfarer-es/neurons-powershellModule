 <#
    .SYNOPSIS
    Get Neurons Data Services data based on the supplied filter parameters.

    .DESCRIPTION
    Queries Neurons Data Services based on the supplied query to retrieve a list of device IDs. Then it proceeds to delete those devices from Neurons.

    .PARAMETER Landscape
    Mandatory. Landscape for the desired customer.
    
    .PARAMETER DataEndpoint
    Optional. Provide the data endpoint for which you want to delete data. 

    .PARAMETER FilterString
    Optional. String to specify Data Services filter string. Don't include "filer=".
    
    .PARAMETER SelectString
    Optional. String to specify Data Services select string. Don't include "select=".

    .PARAMETER ExportToCsv
    Optional. Boolean to specify that results to be saved in a CSV file.  CSV files will be stored under C:\Ivanti\Reports\.

    .PARAMETER CSVPath
    Optional. String to specify a specific path and name of the CSV file.  

    .PARAMETER Token
    Mandatory. JWT token for accessing Data Services. 

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

function Get-NeuronsDataAll {
    #Input parameters. These need to be collected at time of execution.
    param (
    
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$Landscape,
        
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$DataEndpoint="device",

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$FilterString="false",

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$DiscoveryId,
    
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$CSVPath="$PSScriptRoot\Data\",

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$Token

    )
    
    switch ( $Landscape.ToLower() )
    {
        "uks" { $_landscape = "uksprd-sfc.ivanticloud.com" }
        "uku" { $_landscape = "ukuprd-sfc.ivanticloud.com" }
        "nvz" { $_landscape = "nvzprd-sfc.ivanticloud.com" }
        "nvu" { $_landscape = "nvuprd-sfc.ivanticloud.com" }
        "mlz" { $_landscape = "mlzprd-sfc.ivanticloud.com" }
        "mlu" { $_landscape = "mluprd-sfc.ivanticloud.com" }
    }

    switch ( $DataEndpoint.ToLower() )
    {
        "device" { $_dataEndpoint = "device" }
        "user" { $_dataEndpoint = "data" }
        "group" { $_dataEndpoint = "data" }
        "invoice" { $_dataEndpoint = "data" }
        "business units" { $_dataEndpoint = "data" }
        "entitlement" { $_dataEndpoint = "data" }
        "data" { $_dataEndpoint = "data" }
    }

    #CSV setup
    $_csvPath = $CSVPath
    $_csvPathName = $_csvPath + $DiscoveryId + ".json"
    New-Item -ItemType Directory -Force -Path $_csvPath
    Clear-Content $_csvPathName

    #Query URL setup
    $_queryURL = "https://$_landscape/api/discovery/v1/$_dataEndpoint"+"?`$filter=$FilterString&`$colset=all"

    #Headers setup
    $_headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $_headers.Add("content-type", "application/json;charset=UTF-8")
    $_headers.Add("Authorization", "Bearer $Token")

    try {
        #Initial query to Neurons to get result count
        $_response = Invoke-Command -ScriptBlock {
            Invoke-RestMethod -Uri $_queryURL -Method 'GET' -Headers $_headers
        }

        #Convert to valide json if needed
        if ( $_response.gettype() -eq [string] ) {
            $_response = $_response.value | ConvertFrom-InvalidJson
        }

        $_response.value | Add-Content -Path $_csvPathName
        return "200"
    } catch {
        throw "Couldn't get record data for DiscoveryId=$DiscoveryId"
    } 
}