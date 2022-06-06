 <#
    .SYNOPSIS
    Delete Neurons Data Services data based on the supplied filter parameters.

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

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$FilterString,

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

    #Query URL setup
    $_queryURL = "https://$_landscape/api/discovery/v1/$_dataEndpoint"+"?`$filter=$FilterString&`$select=DiscoveryId"

    #Headers setup
    $_headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $_headers.Add("content-type", "application/json;charset=UTF-8")
    $_headers.Add("Authorization", "Bearer $Token")
    $_headers.Add("Uno.TenantId", "$TenantId")

    $_page = 1
    $_results = @()

    do {
        #Initial query to Neurons to get result count
        $_response = Invoke-Command -ScriptBlock {
            Invoke-RestMethod -Uri $_queryURL -Method 'GET' -Headers $_headers
        }

        #Convert to valide json if needed
        if ($_response.gettype() -eq [string]) {
            $_response = $_response | ConvertFrom-InvalidJson
        }

        # calculate PageSize for Number of Pages calculation
        If($_page -eq 1){
            if($_response.value.Count -ne $_response.'@odata.count') {
                $PageSize = $_response.value.Count
            } else {
                $PageSize = $_response.'@odata.count'
            }
        }
 
        #Get the number of pages
        if (!$_pages) {
            $_pages = [math]::ceiling($_response.'@odata.count' / $PageSize)
        }

        $_dbgMessage = "Processing page $_page of $_pages"
        Write-Host $_dbgMessage

        #Process and submit each record in the batch
        foreach ($_result in $_response.value) {
            $_results += $_result.DiscoveryId
        }

        $_queryURL = $_response.'@odata.nextLink'
        $_page++
       
    } until ($_page -ge ($_pages+1))

    return $_results
}
