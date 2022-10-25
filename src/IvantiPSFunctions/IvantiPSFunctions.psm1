<#

    .Author
        Ivanti
    .SYNOPSIS
        A simple module that uses dot sourcing to load all the functions used in Ivanti's Generic PowerShell connector.
    .DESCRIPTION
        When this module is imported, the functions are loaded in memory using dot sourcing.
    .PARAMETER DevMode
    Optional. Set to true when running in development 

    .Version
        1.0.1
    .LastUpdated
        2020-10-01

#>
param  (

    [parameter(Position=0, Mandatory=$false, ValueFromPipeline = $false)]
    [string]$DevMode="false"

)

# Get the path to the function files...
$functionPath = $PSScriptRoot + "\Functions\"

# Get a list of all the function category folder names...
$functionCategoryList = Get-ChildItem -Path $functionPath -Name

# Loop over all the folders, get the functions, and dot source them into memory...
foreach ($functionCategory in $functionCategoryList) {

    #Get all functions in the current folder
    $functionCategoryPath = ($functionPath + $functionCategory + "\")
    $functionList = Get-ChildItem -Path $functionCategoryPath -Name

    #Loop through all the functions in the current function category folder and dot source them
    foreach ($function in $functionList) {
        $Path = $functionCategoryPath + $function
        if ($IsWindows) {
            $Signed = Get-AuthenticodeSignature -FilePath $Path
            #Check to see if we're in production and if so verify all functions are signed
            if ($DevMode -ne "true" -and $Signed.Status -ne "Valid") {
                Write-Error "One or more scripts are not signed."
                Exit
            }
        }

        . ($functionCategoryPath + $function)
    }
}