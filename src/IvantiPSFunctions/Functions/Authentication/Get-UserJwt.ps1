 <#
    .SYNOPSIS
    Run to get a user jwt token.

    .DESCRIPTION
    Run to get a JWT token with the supplied user and Neurons tenant.

    .PARAMETER NeuronsURL
    Mandatory. The URL to the authentication server.
    
    .PARAMETER User
    Mandatory. The client identifier issues during the app registration process.
    
    .PARAMETER Password
    Mandatory. The client secret issues during the app registration process.

    .PARAMETER Token
    Optional. An existing token to check if it needs to be refreshed.

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

#Function to generate authorization token using client credentials.
function Get-UserJwt {
    param (

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$NeuronsURL,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$User,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$Password,
        
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$Token

    )

    if ( $Token ) {
        $_tokenDetails = Invoke-ParseJWTToken -Token $Token
        $_dateTimeNow = Get-Date
        $_dateTimeNowEpoch = Get-Date $_dateTimeNow -Uformat %s

        if ( ($_tokenDetails.exp - $_dateTimeNowEpoch) -gt 600) {
            $_jwt = $Token
        } 
    }
        
    if ( $null -eq $_jwt ) {
        $a = Get-Selenium
        if ($a.Status -ne '200') {
            throw "Selenium failed to install.  Can't continue."
            Exit
        }
    
        $a = Invoke-UpdateChromeDriver
        if ($a.Status -ne '200') {
            throw "Chrome driver failed to install.  Can't continue."
            Exit
        }
    
        try {
            
            $ChromeDriver = Start-SeChrome
    
            # Launch a browser and go to URL
            $ChromeDriver.Navigate().GoToURL($NeuronsURL)
    
            #Login
            $ChromeDriver.FindElementByXPath('//*[@id="Username"]').SendKeys($User)
            $ChromeDriver.FindElementByXPath('//*[@id="Password"]').SendKeys($Password)
            $ChromeDriver.FindElementsByTagName('button')[0].Click()
    
            #Get user JWT
            $seleniumWait = New-Object -TypeName OpenQA.Selenium.Support.UI.WebDriverWait($ChromeDriver, (New-TimeSpan -Seconds 10))
            $seleniumWait.Until([OpenQA.Selenium.Support.UI.ExpectedConditions]::ElementIsVisible([OpenQA.Selenium.By]::ClassName(("home-title")))) | Out-Null
            $_jwtFound = $ChromeDriver.ExecuteScript("return sessionStorage.getItem('jwt')")
            $_jwt = [string]$_jwtFound
    
            # Cleanup
            $ChromeDriver.Close()
            $ChromeDriver.Quit()
    
        } catch {
            throw "Couldn't get a user JWT"
        }
    }
    return $_jwt
}