 <#
    .SYNOPSIS
    Get Neurons Data Services data based on the supplied filter parameters.

    .DESCRIPTION
    Queries Neurons Data Services based on the supplied query to retrieve a list of device IDs. Then it proceeds to delete those devices from Neurons.

    .PARAMETER TenantId
    Mandatory. Tenant ID for the desired customer.

    .PARAMETER Landscape
    Mandatory. Landscape for the desired customer.
    
    .PARAMETER DataEndpoint
    Mandatory. Provide the data endpoint for which you want to delete data. 

    .PARAMETER FilterString
    Mandatory. Data Services filter string excluding "filer="

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
        [String]$TenantId,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$Landscape,
        
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$DataEndpoint="device",

        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$FilterString="exists(DiscoveryId)",

        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$SelectString="DiscoveryId",

        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [bool]$ExportToCsv,

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
        $_reportRunTime = Get-Date -Format "yyyy-MM-dd HH-mm-ss"
        $_csvPath = "C:\Ivanti\Reports\Data Services Data Report "+$_reportRunTime+".csv"

        foreach ( $_selectValue in $_selectValues ) {
            $_selectValue=$_selectValue.Replace("/", ".")
            $_csvHeader += '"'+$_selectValue+'",'
        }

        $_csvHeader.Substring( 0, $_csvHeader.length -1 ) | Add-Content -Path $_csvPath
    }

    #Filter cleanup
    IF ([string]::IsNullOrWhitespace($FilterString)) { $FilterString = "exists(DiscoveryId)" }

    #Query URL setup
    $_queryURL = "https://$_landscape/api/discovery/v1/$_dataEndpoint"+"?`$filter=$FilterString&`$select=$SelectString"

    #Headers setup
    $_headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $_headers.Add("content-type", "application/json;charset=UTF-8")
    $_headers.Add("Authorization", "Bearer $Token")
    $_headers.Add("Uno.TenantId", "$TenantId")

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
        If($_page -eq 1){
            if( $_response.value.Count -ne $_response.'@odata.count') {
                $PageSize = $_response.value.Count
            } else {
                $PageSize = $_response.'@odata.count'
            }
        }
 
        #Get the number of pages
        if (!$_pages) {
            $_pages = [math]::ceiling( $_response.'@odata.count' / $PageSize )
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
                $_resultRow | Add-Content -Path $_CSVPath
            }
            $_results += $_resultRow
        }

        $_queryURL = $_response.'@odata.nextLink'
        $_page++
       
    } until ( $_page -ge ( $_pages + 1) )

    if ( $ExportToCsv -eq $true ) {
        $_dbgMessage = "Successfully got "+$_results.count+' records. CSV file is located at "'+$_csvPath+'"'
        return $_dbgMessage
    }
    return $_results
}
