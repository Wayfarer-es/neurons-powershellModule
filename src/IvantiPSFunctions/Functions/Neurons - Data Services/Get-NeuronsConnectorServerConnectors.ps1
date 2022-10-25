 <#
    .SYNOPSIS
    Delete Neurons Data Services data based on the supplied filter parameters.

    .DESCRIPTION
    Queries Neurons Data Services based on the supplied query to retrieve a list of device IDs. Then it proceeds to delete those devices from Neurons.

    .PARAMETER Landscape
    Mandatory. Landscape for the desired customer.

    .PARAMETER ConnectorServerName
    Mandatory. Connector Server Name (ie. what's shown in the UI).

    .PARAMETER Token
    Mandatory. JWT token for accessing Data Services. 

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

function Get-NeuronsConnectorServerConnectors {
    #Input parameters. These need to be collected at time of execution.
    param (
    
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$Landscape,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$ConnectorServerName,

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

    $_connectorServerName = $ConnectorServerName.ToLower()

    #Query URL setup
    $_queryURL = "https://$_landscape/api/settings/odata/Configurations?`$expand=Parameters&`$filter=DeviceName eq '$_connectorServerName'"  

    #Headers setup
    $_headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $_headers.Add("content-type", "application/json;charset=UTF-8")
    $_headers.Add("Authorization", "Bearer $Token")
    $_headers.Add("Uno.TenantId", "$TenantId")

    try {
        #Initial query to Neurons to get result count
        $_response = Invoke-Command -ScriptBlock {
            Invoke-RestMethod -Uri $_queryURL -Method 'GET' -Headers $_headers
        }
        return $_response
       
    } catch {
        throw "Connector server request failed."
    }

}