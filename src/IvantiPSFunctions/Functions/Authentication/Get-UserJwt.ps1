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
        [String]$Password

    )

    $_checkForSelenium = Invoke-Command -ScriptBlock {
        Get-Selenium
    }

    if ( $_checkForSelenium -eq "100" ) {
        throw "Selenium failed to install.  Can't continue."
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
        $_loginUrl = $ChromeDriver.Url
        $_jwtFound = $_loginUrl -match '(?<=access_token=)(.*)(?=&token_type=)'
        if ( $_jwtFound ) {
            $_jwt = $matches[1]
        }

        # Cleanup
        $ChromeDriver.Close()
        $ChromeDriver.Quit()

        return $_jwt

    } catch {
        throw "Couldn't get a user JWT"
    }

}