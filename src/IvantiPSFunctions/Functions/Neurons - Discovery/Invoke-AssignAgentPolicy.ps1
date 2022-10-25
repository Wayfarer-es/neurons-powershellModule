 <# ********************* Still a WIP *********************
    .SYNOPSIS
    Assign agent policy to devices via a query.

    .DESCRIPTION
    Assigns an agent policy to the provided devices.

    .PARAMETER AgentPolicyId
    Mandatory. Agent Policy Id ID for the desired Agent Policy.

    .PARAMETER Landscape
    Mandatory. Landscape for the desired customer.
    
    .PARAMETER DeviceData
    Mandatory. Provide the hashtable of DeviceId, DeviceName, and Platform values for your respective devices.

    .PARAMETER Landscape
    Mandatory. OS Platform for the devices (Windows, Mac, Linux).

    .PARAMETER Token
    Mandatory. JWT token for accessing Data Services. 

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

function Invoke-AssignAgentPolicy {
    #Input parameters. These need to be collected at time of execution.
    param (
    
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$AgentPolicyId,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$Landscape,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [Object[]]$DeviceData,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$Platform,

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

    #Query URL setup
    $_queryURL = 'https://'+$_landscape+'/disco/QueueDevices'

    #Headers setup
    $_headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $_headers.Add("content-type", "application/json;charset=UTF-8")
    $_headers.Add("Authorization", "Bearer $Token")

    foreach ($_record in $DeviceData) 
    {
        
        #Body setup
        $_body = @{
            DeviceId = $_record.DeviceId
            DeviceName = $_record.DeviceName
            Platform = $Platform
            PolicyGroupId = $AgentPolicyId
        }

        #Call to change Agent Policy
        $_response = Invoke-Command -ScriptBlock {
            Invoke-RestMethod -Uri $_queryURL -Method 'POST' -Headers $_headers -Body $_body
        }

        #Response message
        if ($_response -notcontains "error") {
            $_dbgMessage = "Successfully changed policy for $_record.DeviceName with response code $_response"
            Write-Host $_dbgMessage
        } else {
            $_dbgMessage = "Failed to change policy for $_record.DeviceName"
            Write-Host $_dbgMessage
        }
        
    } 

}