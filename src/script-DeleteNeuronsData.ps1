#Import Module
if (Test-Path ".\IvantiPSFunctions\IvantiPSFunctions.psm1" -PathType leaf) {
    $Module = Get-Item ".\IvantiPSFunctions\IvantiPSFunctions.psm1" | Resolve-Path -Relative
    Write-Debug "Found module file"
} elseif (Test-Path ".\src\IvantiPSFunctions\IvantiPSFunctions.psm1" -PathType leaf) {
    $Module = Get-Item ".\src\IvantiPSFunctions\IvantiPSFunctions.psm1" | Resolve-Path -Relative
    Write-Debug "Found module file"
} else {
    throw "PowerShell module cannot be found."
    Exit
}
Import-Module -Name $Module -ArgumentList $DevMode -Force

#Set parameters to run
$_NeuronsURL = $_environment.tenant_url
$_user = $_environment.user
$_password = $_environment.password
$_landscape = $_environment.landscape
$_userJWT = Get-UserJwt -NeuronsURL $_NeuronsURL -User $_user -Password $_password

# *************** Parameters to modify for script to run ***************
$_daysAgo = (Get-Date).AddDays(-90)
$_date = Get-Date -Date $_daysAgo -Format 'yyyy-MM-dd'
$_filter = "DiscoveryMetadata.DiscoveryServiceLastUpdateTime le '$_date'"

#Run code
$_deviceIds = Get-NeuronsData -Landscape $_landscape -FilterString $_filter -Token $_token
if ($null -ne $_deviceIds -or $_deviceIds) {
    Invoke-DeleteNeuronsData -Landscape $_landscape -DataEndpoint 'device' -DiscoveryIds $_deviceIds -Token $_userJWT
} else {
    $_dbgMessage = "No devices to delete"
    Write-Host $_dbgMessage
}
