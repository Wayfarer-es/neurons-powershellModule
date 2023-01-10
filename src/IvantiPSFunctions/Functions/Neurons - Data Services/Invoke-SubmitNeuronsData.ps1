 <#
    .SYNOPSIS
    Submit data to Neurons Data Services.

    .DESCRIPTION
    Submits a record to Neurons Data Services.

    .PARAMETER Record
    Mandatory. The json record you're submitting.

    .PARAMETER Landscape
    Mandatory. Landscape for the desired customer.
    
    .PARAMETER DataEndpoint
    Mandatory. Provide the data endpoint for which you want to delete data. 

    .PARAMETER Provider
    Mandatory. The provider source for the record.

    .PARAMETER Token
    Mandatory. JWT token for accessing Data Services. 

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

function Invoke-SubmitNeuronsData {
    #Input parameters. These need to be collected at time of execution.
    param (

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [object]$Record,
    
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$Landscape,
        
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$DataEndpoint,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$Provider,

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

    #Post URL setup
    $_queryURL = "https://$_landscape/api/inventorygateway/v1/batch/$_dataEndpoint/$Provider"

    #Headers setup
    $_headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $_headers.Add("content-type", "application/json;charset=UTF-8")
    $_headers.Add("Authorization", "Bearer $Token")

    try {
        #Initial query to Neurons to get result count
        $_response = Invoke-Command -ScriptBlock {
            Invoke-RestMethod -Uri $_queryURL -Method 'POST' -Headers $_headers -Body $Record
        }

        #Convert to valide json if needed
        if ( $_response.gettype() -eq [string] ) {
            $_response = $_response | ConvertFrom-InvalidJson
        }
        
        if ( $null -eq $_response ) {
            return @{"Status"=200}
        } else {
            throw "Failed to submit record for Provider=$Provider and Endpoint=$_dataEndpoint"
        }

    } catch {
        throw "Failed to submit record for Provider=$Provider and Endpoint=$_dataEndpoint"
    } 
}
