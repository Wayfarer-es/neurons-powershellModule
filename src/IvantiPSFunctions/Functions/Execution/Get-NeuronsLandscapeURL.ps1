 <#
    .SYNOPSIS
    Use this function to try get the Neurons landscape URL.

    .DESCRIPTION
    Returns the specific Neurons API URL prefix for a given landscape friendly name (ie. NVU, UVU, etc.)

    .PARAMETER Landscape
    Mandatory. Provide the friendly name of the landscape for which you want the corresonding API URL.

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

function Get-NeuronsLandscapeURL {
    [CmdletBinding()]
    Param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Landscape
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

    return $_landscape
    
}