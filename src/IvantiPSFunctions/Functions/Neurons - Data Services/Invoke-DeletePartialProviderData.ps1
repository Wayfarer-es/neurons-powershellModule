 <#
    .SYNOPSIS
    Delete Neurons Data Services data for a particular provider based on the supplied filter parameters.

    .DESCRIPTION
    Deletes Neurons Data Services provider data (not entire record) based on the supplied device IDs and provider name.

    .PARAMETER Landscape
    Mandatory. Landscape for the desired customer.

    .PARAMETER DataEndpoint
    Mandatory. Provide the data endpoint for which you want to delete data. 

    .PARAMETER Landscape
    Mandatory. Landscape for the desired customer.

    .PARAMETER Provider
    Mandatory. Provider type for the provider.

    .PARAMETER Token
    Mandatory. JWT token for accessing Data Services. 

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

function Invoke-DeletePartialProviderData {
    #Input parameters. These need to be collected at time of execution.
    param (

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$Landscape,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$DataEndpoint,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$Provider,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [Array]$DiscoveryIds,

        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [int]$BatchSize = 50,
        
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$Token

    )
    
    #Parameter setup   
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
    
    if ( $Provider -eq "LDMS") {
        $_provider = "['ldms-common', 'ldms-software', 'ldms-hardware']"
    } else {
        $_provider = "'$Provider'"
    }

    #Base URL setup
    $_baseUrl = "https://$_landscape/api/discovery/v1/$_dataEndpoint/partial"

    #Headers setup
    $_headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $_headers.Add("Accept", "application/json")
    $_headers.Add("Content-Type", "application/x-www-form-urlencoded")
    $_headers.Add("Authorization", "Bearer $Token")
    $_headers.Add("Uno.TenantId", "$TenantId")
    
    #Run code
    #Calculate how many batches to run
    $_numPages = [int][Math]::Ceiling($DiscoveryIds.Length / $BatchSize)

    #Iterate through batch
    for ( ($a = 0); ($a -lt $_numPages); $a++ ) {
        
        $_start = $a * $BatchSize
        $_end = ( ($a + 1) * $BatchSize ) - 1

        #First record in batch
        $_recID = $DiscoveryIds[$_start]
        $_queryStringPart = "( _routing eq '$_recID'"

        #Iterate through other records in batch
        for ( ($b = ($_start + 1)); ($b -le $_end ); $b++ ) {
            $_recID = $DiscoveryIds[$b]
            $_queryStringPart += " or _routing eq '$_recID'"
        }

        #Close off query string
        $_queryStringPart += ")"
        
        #Body setup
        $_body = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $_body.Add("queryString", "`$filter=_provider eq $_provider and $_queryStringPart")

        #Run delete request
        $_result = Invoke-Command -ScriptBlock {
            Invoke-RestMethod -Uri $_baseUrl -Method 'DELETE' -Headers $_headers -Body $_body
        }

        #Result response
        if ($_result -notcontains "error") {
            $_dbgMessage = "Successfully deleted batch " + ($a+1) +" of "+ ($_numPages)
            Write-Host $_dbgMessage
        } else {
            $_dbgMessage = "Failed to delete batch " + ($a+1) +" of "+ ($_numPages)
            Write-Host $_dbgMessage
        }

    }

}