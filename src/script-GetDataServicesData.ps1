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

#Import environment
$_environmentConfig = Get-Content -Path "$PSScriptRoot\Environment\environment-config.json" | ConvertFrom-Json
$_environment = $_environmentConfig.($_environmentConfig.default)  

#Set parameters to run
$_clientID = $_environment.client_id
$_clientSecret = $_environment.client_secret
$_authURL = $_environment.auth_url
$_scope = "dataservices.read"
$_landscape = $_environment.landscape

# *************** Parameters to modify for script to run ***************
$_endpoint = "device"
$_filter = "_provider eq 'ivantiinventoryengine'&`$providerFilter=ivantiinventoryengine"
$_select = "DiscoveryId,DeviceName,Network/NICAddress"

#Run code
$_token = Get-AccessToken -AuthURL $_authURL -ClientID $_clientID -ClientSecret $_clientSecret -Scopes $_scope

$_results = Invoke-Command -ScriptBlock {
    Get-NeuronsData -Landscape $_landscape -DataEndpoint $_endpoint -FilterString $_filter -SelectString $_select -ExportToCsv $true -CSVPath "$PSScriptRoot/Data/Test File" -Token $_token 
}

$_results