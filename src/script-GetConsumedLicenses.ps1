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

#Set parameters to run
$_clientID = "[insert client id here]"
$_clientSecret = "[insert client secret here]"
$_authURL = "[insert auth URL here]"
$_scope = "dataservices.read"
$_landscape = "NVU"
$_csvName = "Neurons Consumed Licenses"
$_daysAgo = (Get-Date).AddDays(-90)
$_date = Get-Date -Date $_daysAgo -Format 'yyyy-MM-dd'

#Static script parameters
$_filter = "DiscoveryMetadata.Providers.processDate gt '$_date' and (contains(OS.Name, 'windows') or contains(OS.Name, 'mac') or (contains(OS.Name, 'red hat') and contains(OS.Name, '7')) or (contains(OS.Name, 'centos') and contains(OS.Name, '7')) or not contains(OS.Name, 'phone'))"
$_select = "DeviceName,OS/Name,DiscoveryMetadata/Providers/processDate"

#Run code
if ( $_userJWT) { $_token = $_userJWT } else { $_token = Get-AccessToken -AuthURL $_authURL -ClientID $_clientID -ClientSecret $_clientSecret -Scopes $_scope }

$_results = Invoke-Command -ScriptBlock {
    Get-NeuronsData -Landscape $_landscape -FilterString $_filter -SelectString $_select -ExportToCsv $true -CSVName $_csvName -Token $_token 
}

$_results
