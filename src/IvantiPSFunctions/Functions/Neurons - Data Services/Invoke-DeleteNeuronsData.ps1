 <#
    .SYNOPSIS
    Deletes Neurons Data Services data
    
    .DESCRIPTION
    Delete Neurons Data Services data based on the supplied discovery IDs.

    .PARAMETER TenantId
    Mandatory. Tenant ID for the desired customer.

    .PARAMETER Landscape
    Mandatory. Landscape for the desired customer.

    .PARAMETER DataEndpoint
    Mandatory. Provide the data endpoint for which you want to delete data. 

    .PARAMETER DiscoveryId
    Mandatory. Provide a list of discovery IDs (ie. data services IDs) for which you want to delete."

    .PARAMETER Token
    Mandatory. JWT token for accessing Data Services. 

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

function Invoke-DeleteNeuronsData {
    #Input parameters. These need to be collected at time of execution.
    param (
    
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$Landscape,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$DataEndpoint,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [Array]$DiscoveryIds,

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
    }

    #Headers setup
    $_headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $_headers.Add("content-type", "application/json;charset=UTF-8")
    $_headers.Add("Authorization", "Bearer $Token")

    foreach ($_record in $DiscoveryIds) 
    {

        #Query URL setup
        $_filter = "exists(DiscoveryId) and DiscoveryId eq '$_record'"
        $_queryURL = "https://$_landscape/api/discovery/v1/"+$_dataEndpoint+"?`$filter=$_filter"

        #Initial query to Neurons to get result count
        $_result = Invoke-Command -ScriptBlock {
            Invoke-RestMethod -Uri $_queryURL -Method 'DELETE' -Headers $_headers
        }

        #Convert to valid json if needed
        if ($_result -notcontains "error") {
            $_dbgMessage = "Successfully deleted $_record with response code $_result"
            Write-Host $_dbgMessage
        } else {
            $_dbgMessage = "Failed to delete $_record"
            Write-Host $_dbgMessage
        }

    } 

}