 <#
    .SYNOPSIS
    Send Neurons data to Splunk.

    .DESCRIPTION
    Queries Neurons Data Services based on the supplied filter and select statements and then sends that data to Splunk.

    .PARAMETER TenantId
    Mandatory. Tenant ID for the desired customer.

    .PARAMETER Landscape
    Mandatory. Landscape for the desired customer.

    .PARAMETER FilterString
    Mandatory. Data Services filter string excluding "filer="

    .PARAMETER Token
    Mandatory. JWT token for accessing Data Services. 

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

#Neurons to Splunk input parameters. These need to be collected at time of execution.
param (
    
    [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
    [String]$TenantId,

    [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
    [String]$Landscape,

    [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
    [String]$NeuronsToken,

    [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
    [String]$SplunkURL,

    [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
    [String]$SplunkToken,

    [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
    [String]$FilterString,

    [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
    [String]$SelectString,

    [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
    [string]$DevMode="false"

)

# *************************** Import Ivanti Neurons PowerShell Module *************************** 
if (Test-Path ".\IvantiPSFunctions\IvantiPSFunctions.psm1" -PathType leaf) {
    $Module = Get-Item ".\IvantiPSFunctions\IvantiPSFunctions.psm1" | Resolve-Path -Relative
    Write-Debug "Found module file"
} elseif (Test-Path ".\src\IvantiPSFunctions\IvantiPSFunctions.psm1" -PathType leaf) {
    $Module = Get-Item ".\src\IvantiPSFunctions\IvantiPSFunctions.psm1" | Resolve-Path -Relative
    Write-Debug "Found module file"
} else {
    $StatusCode = "404"
    $Exception = [Exception]::new("PowerShell module cannot be found.  Error code ($($StatusCode))")
    $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
        $Exception,
        "$($StatusCode)",
        [System.Management.Automation.ErrorCategory]::FatalError,
        $TargetObject
    )
    $PSCmdlet.WriteError($ErrorRecord)
    Exit
}

# ----- Check to see if Module is signed ----- 
if ($IsWindows) {
    $Signed = Get-AuthenticodeSignature -FilePath $Module
    if ($DevMode -ne "true" -and $Signed.Status -ne "Valid") {
        Write-Error "Module is not signed."
        Exit
    }
}
else {
    Write-Debug "Skipping module certificate check."
}

# ----- Import Module ----- 
Import-Module -Name $Module -ArgumentList $DevMode -Force

# *************************** Execution Prep *************************** 
# ----- Set & prep parameters -----
$_landscape = Get-NeuronsLandscapeURL -Landscape $Landscape
$_page = 1

If ( ($null -eq $SelectString) -or ($SelectString -eq '') ) { 
    $_selectString = "DiscoveryId,LastHardwareScanDateInLocalTime,DisplayName,Ivanti.AgentFramework.AgentId,LastHardwareScanDate,LoginName,Network.TCPIP.Address,OS.Name,System.ManufacturerName,System.Model,Type" 
} else {
    $_selectString = $SelectString
}
If ( ($null -eq $FilterString) -or ($FilterString -eq '') ) { 
    $_filterString = "exists(DiscoveryId)" 
} else {
    $_filterString = $FilterString
}

# ----- Neurons URL setup ----- 
$_queryURL = "https://$_landscape/api/discovery/v1/device?`$filter=$_filterString&`$select=$_selectString"

# ----- Headers setup ----- 
$_headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$_headers.Add("content-type", "application/json;charset=UTF-8")
$_headers.Add("Authorization", "Bearer $NeuronsToken")
$_headers.Add("Uno.TenantId", "$TenantId")

# *************************** Code Execution *************************** 
$_page = 1

do {
    # ----- Query to Neurons to get data ----- 
    $_neuronsResponse = Invoke-Command -ScriptBlock {
        Invoke-RestMethod -Uri $_queryURL -Method 'GET' -Headers $_headers
    }

    # ----- Convert to valide json if needed ----- 
    if ($_neuronsResponse.gettype() -eq [string]) {
        $_neuronsResponse = $_neuronsResponse | ConvertFrom-InvalidJson
    }

    # ----- Get the number of pages ----- 
    if (!$_pages) {
        $_pages = [math]::ceiling($_neuronsResponse.'@odata.count' / 15)
    }

    $_dbgMessage = "Processing page $_page of $_pages"
    Write-Host $_dbgMessage

    #Process and submit each record in the batch
    foreach ($_result in $_neuronsResponse.value) {
        $_resultData = $_result | ConvertTo-Json -Depth 99
        $_splunkResponse = Invoke-Command -ScriptBlock {
            Send-SplunkData -SplunkServer $SplunkURL -Token $SplunkToken -Data $_resultData
            #Send-SplunkEvent -InputObject $_resultData -Uri $SplunkURL -Key $SplunkToken 
        }
        
        if ($_splunkResponse -contains 'error') {
            $_dbgMessage = "Failed to send data for Discovery ID = $_result.DiscoveryId to Splunk"
            Write-Host $_dbgMessage
        } else {
            $_discoveryId = $_result.DiscoveryId
            $_dbgMessage = "Sent $_discoveryId to Splunk"
            Write-Host $_dbgMessage
        }
    }

    $_queryURL = $_neuronsResponse.'@odata.nextLink'
    $_page++
    
} until ($_page -ge ($_pages+1))