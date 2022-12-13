 <#
    .SYNOPSIS
    Run selenium test on a website and return results.

    .DESCRIPTION
    Analyzes the loading time for a website or a particular set of steps via the provided selecium test.

    .PARAMETER SeleniumTestScriptFile
    Mandatory. File path to the desired selenium test file.

    .PARAMETER OutputFile
    Mandatory.  File path to the desired output test file.

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

#Neurons to Splunk input parameters. These need to be collected at time of execution.
param (
    
    [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
    [String]$SeleniumTestScriptFile,

    [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
    [String]$SeleniumResultsFile

)

# *************************** Module Prep ***************************
if (Get-InstalledModule -Name 'Selenium' -RequiredVersion '3.0.1') {
    Write-Host "Selenium module exists"
} 
else {
    Write-Host "Selenium module does not exist. Trying to install now."
    try {
        Install-Module -Name Selenium -RequiredVersion 3.0.1 -Scope CurrentUser
    } 
    catch {
        throw "Couldn't install Selenium module."
    }
}

# *************************** Selenium Script File Prep ***************************
if (-not(Test-Path -Path $SeleniumTestScriptFile -PathType Leaf)) {
    throw "Selenium script file doesn't exist.  Please verify that the file is placed in the supplied directory."
}
else {
    $_scriptFile = Get-Item -Path $SeleniumTestScriptFile
}

# *************************** Results File Prep ***************************
if (-not(Test-Path -Path $SeleniumResultsFile -PathType Leaf)) {
    try {
        $_resultsFile = New-Item -ItemType File -Path $SeleniumResultsFile -Force -ErrorAction Stop
    }
    catch {
        throw $_.Exception.Message
    }
}
else {
    Clear-Content -Path $SeleniumResultsFile
    $_resultsFile = Get-Item -Path $SeleniumResultsFile
}

# *************************** Initialize Selenium Chrome ***************************
#$_driver = Start-SeChrome

# *************************** Code Execution *************************** 

For ($a = 0; $a -lt 5; $a++) {
    $_driver = Start-SeChrome
    #$_navigationStart = $_driver.Navigate().GoToURL('https://www.google.com')
    $_driver.Url = "https://www.google.com"
    $_navigationStart = $_driver.ExecuteScript("return window.performance.timing.navigationStart")
    $_domContentLoadedEventEnd = $_driver.ExecuteScript("return window.performance.timing.domContentLoadedEventEnd")
    $_loadEventEnd = $_driver.ExecuteScript("return window.performance.timing.loadEventEnd")

    $_backendPerformance = ($_domContentLoadedEventEnd - $_navigationStart)/1000
    $_frontendPerformance = ($_loadEventEnd - $_navigationStart)/1000
    Add-Content -Path $_resultsFile -Value "Test $a - Backend Performance - $_backendPerformance"
    Add-Content -Path $_resultsFile -Value "Test $a - Frontend Performance - $_frontendPerformance"
    $_driver.Close()
}

$_driver.Quit()