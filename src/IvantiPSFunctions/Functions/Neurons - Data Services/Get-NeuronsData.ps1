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

function Get-NeuronsData {
    #Input parameters. These need to be collected at time of execution.
    param (
    
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$Landscape,
        
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$DataEndpoint="device",

        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$FilterString="exists(DiscoveryId)",

        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$SelectString="DiscoveryId",

        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [bool]$ExportToCsv=$false,

        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$CSVPath="$PSScriptRoot\Reports\Neurons Report",

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

    #Split select values into array for use throughout the function
    $_selectValues = $SelectString.Split(",") 

    #CSV setup
    if ( $ExportToCsv -eq $true ) {
        
        if ( $CSVPath -eq "$PSScriptRoot\Reports\Neurons Report") {
            $_reportRunTime = Get-Date -Format "yyyy-MM-dd HH-mm-ss"
            $_csvPathName = $CSVPath + "Report - " + $_reportRunTime + ".csv"

        } else {
            if ( $CSVPath.contains(".csv") ) {
                $_csvPathName = $CSVPath
            } else {
                $_csvPathName = $CSVPath + ".csv"
            }  
            
            $_csvName = $CSVPath -match '^(.*[\\\/])'
            if ( $_csvName ) {
                $CSVPath = $matches[1]
            }

        }

        New-Item -ItemType Directory -Force -Path $CSVPath
        Clear-Content $_csvPathName
        
        foreach ( $_selectValue in $_selectValues ) {
            $_selectValue=$_selectValue.Replace("/", ".")
            $_csvHeader += '"'+$_selectValue+'",'
        }

        $_csvHeader.Substring( 0, $_csvHeader.length -1 ) | Add-Content -Force -Path $_csvPathName
    }

    #Filter cleanup
    IF ( [string]::IsNullOrWhitespace($FilterString) ) { $FilterString = "exists(DiscoveryId)" }

    #Query URL setup
    $_queryURL = "https://$_landscape/api/discovery/v1/$_dataEndpoint"+"?`$filter=$FilterString&`$select=$SelectString"

    #Headers setup
    $_headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $_headers.Add("content-type", "application/json;charset=UTF-8")
    $_headers.Add("Authorization", "Bearer $Token")

    #Results variable setup
    $_page = 1
    $_results = @()

    do {
        #Initial query to Neurons to get result count
        $_response = Invoke-Command -ScriptBlock {
            Invoke-RestMethod -Uri $_queryURL -Method 'GET' -Headers $_headers
        }

        #Convert to valide json if needed
        if ( $_response.gettype() -eq [string] ) {
            $_response = $_response | ConvertFrom-InvalidJson
        }

        # calculate PageSize for Number of Pages calculation
        If( $_page -eq 1 ){
            if( $_response.value.Count -ne $_response.'@odata.count') {
                $_pageSize = $_response.value.Count
            } else {
                $_pageSize = $_response.'@odata.count'
            }
        }
 
        #Get the number of pages
        if ( !$_pages ) {
            if ( $_pageSize -eq 0 ) {
                $_pages = 1
            } else {
                $_pages = [math]::ceiling( $_response.'@odata.count' / $_pageSize )
            }
        }

        $_dbgMessage = "Processing page $_page of $_pages"
        Write-Host $_dbgMessage

        #Process and submit each record in the batch
        foreach ( $_result in $_response.value ) {
            $_resultRow = ""

            foreach ( $_selectValue in $_selectValues ) {
                $_selectValueArray = $_selectValue.split("/")
                $_resultItem = $_result

                foreach ( $_selectValueArrayItem in $_selectValueArray ) {
                    $_resultItem = $_resultItem.$_selectValueArrayItem
                }

                $_resultRow += '"'+$_resultItem+'",'
            }

            $_resultRow = $_resultRow.Substring( 0, $_resultRow.length -1 )

            if ( $ExportToCsv -eq $true) {
                $_resultRow | Add-Content -Path $_csvPathName
            } else {
                $_resultRow = $_resultRow.replace('"','')
            }
            $_results += $_resultRow
        }

        $_queryURL = $_response.'@odata.nextLink'
        $_page++
       
    } until ( $_page -ge ( $_pages + 1) )

    if ( $ExportToCsv -eq $true ) {
        $_dbgMessage = "Successfully got "+$_results.count+' records. CSV file is located at "'+$_csvPathName+'"'
        return $_dbgMessage
    }
    return $_results
}
