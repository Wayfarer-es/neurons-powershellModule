 <#
    .SYNOPSIS
    Get Neurons Discovered Device Data based on the supplied filter parameters.

    .DESCRIPTION
    Queries Neurons Data Services based on the supplied query to retrieve a list of device IDs. Then it proceeds to delete those devices from Neurons.

    .PARAMETER TenantId
    Mandatory. Tenant ID for the desired customer.

    .PARAMETER Landscape
    Mandatory. Landscape for the desired customer.
    
    .PARAMETER DataEndpoint
    Mandatory. Provide the data endpoint for which you want to delete data. 

    .PARAMETER FilterString
    Mandatory. Filter string for discovered asset attributes.
    Example = {"field":"OperatingSystemName","values":["Windows 10 Enterprise","Microsoft Windows 10 Professional Edition, 64-bit"]}

    .PARAMETER Token
    Mandatory. JWT token for accessing Data Services. 

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

function Get-NeuronsDiscoveredDevicesData {
    #Input parameters. These need to be collected at time of execution.
    param (
    
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$TenantId,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$Landscape,

        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$FilterString,
    
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [bool]$ExportToCsv,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$Token

    )
    
    switch ( $Landscape.ToLower() )
    {
        "uks" { $_landscape = "uks-prd-apim.ivanticloud.com" }
        "uku" { $_landscape = "uks-prd-apim.ivanticloud.com" }
        "nvz" { $_landscape = "nvz-prd-apim.ivanticloud.com" }
        "nvu" { $_landscape = "nvz-prd-apim.ivanticloud.com" }
        "mlz" { $_landscape = "mlz-prd-apim.ivanticloud.com" }
        "mlu" { $_landscape = "mlz-prd-apim.ivanticloud.com" }
    }

    #CSV setup
    if ( $ExportToCsv -eq $true) {
        $_reportRunTime = Get-Date -Format "yyyy-MM-dd HH-mm-ss"
        $_CSVPath = "C:\Ivanti\Reports\Discovered Data Report "+$_reportRunTime+".csv"
        '"Device Name","Hostname","DiscoveryId","AgentId","MacAddress","IPAddress","LastCheckIn"' | Add-Content -Path $_CSVPath
    }

    #Headers setup
    $_headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $_headers.Add("content-type", "application/json;charset=UTF-8")
    $_headers.Add("Authorization", "Bearer $Token")

    $_page = 0
    $_pageSize = 20
    $_results = @()

    do {
        
        #Query URL setup
        $_queryURL = 'https://'+$_landscape+'/disco/discoveredassets?dataRequest={"notNullColumns":[["AgentIdentity","ScannedByAgentId"]],"nullColumns":[],"selected":[],"deselected":[],"trackDeselectedFilters":false,"skip":'+($_page*$_pageSize)+',"take":'+$_pageSize+',"inFilters":['+$FilterString+'],"notInFilters":[],"searchableColumns":[],"tenantId":"'+$TenantId+'"}'

        #Initial query to Neurons to get result count
        $_response = Invoke-Command -ScriptBlock {
            Invoke-RestMethod -Uri $_queryURL -Method 'GET' -Headers $_headers
        }

        #Convert to valide json if needed
        if ($_response.gettype() -eq [string]) {
            $_response = $_response | ConvertFrom-InvalidJson
        }

        #Get the number of pages
        if (!$_pages) {
            $_pages = [math]::ceiling($_response.totalCount / $_pageSize)
        }

        $_dbgMessage = "Processing page "+($_page+1)+" of "+$_pages
        Write-Host $_dbgMessage

        #Process and submit each record in the batch
        foreach ($_result in $_response.records) {
            $_resultRow = '"'+$_result.deviceName+'","'+$_result.hostName+'","'+$_result.Id+'","'+$_result.agentIdentity+'","'+$_result.macAddress+'","'+$_result.lastKnownIPAddress+'","'+$_result.lastCheckIn+'"'
            if ( $ExportToCsv -eq $true) {
                $_resultRow | Add-Content -Path $_CSVPath
            }
            $_results += $_resultRow
        }
        
        $_page++

    } until ($_page -ge ($_pages))

    if ( $ExportToCsv -eq $true) {
        $_dbgMessage = "Successfully got "+$_results.count+' records. CSV file is located at "'+$_CSVPath+'"'
        return $_dbgMessage
    }
    return $_results
}