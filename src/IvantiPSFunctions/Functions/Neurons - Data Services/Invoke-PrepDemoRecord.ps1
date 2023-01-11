 <#
    .SYNOPSIS
    Preps a record to import into another tenant.

    .DESCRIPTION
    Removes unnecessary data and updates the dates of an Ivanti Neurons record so it can be imported.

    .PARAMETER Record
    Mandatory. Json record of an Ivanti Neurons tenant.

    .PARAMETER DateRandomizer
    Optional. Boolean to specify if all the dates should be updated and randomized from the last 7 days.

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

function Invoke-PrepDemoRecord {
    #Input parameters. These need to be collected at time of execution.
    param (
    
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [object]$Record,
        
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [bool]$DateRandomizer="false"

    )
    
    $_record = $Record | ConvertFrom-Json
    $_record.PsObject.Properties.Remove('DiscoveryId')
    $_record.PsObject.Properties.Remove('Ivanti')
    $_record.DiscoveryMetadata.PsObject.Properties.Remove('Providers')
    $_record.DiscoveryMetadata.PsObject.Properties.Remove('Providers_pkAttrName_name')
    $_record.DiscoveryMetadata.PsObject.Properties.Remove('Providers_pkAttrName')
    $_record.DiscoveryMetadata.PsObject.Properties.Remove('DiscoveryServiceLastUpdateTime')

    $_results = $_record | ConvertTo-Json -Depth 100

    return $_results
}
