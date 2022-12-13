function Get-Selenium {
    # *************************** Module Prep ***************************
    if (Get-InstalledModule -Name 'Selenium' -RequiredVersion '3.0.1') {
        Write-Host "Selenium module exists"
        Return "200"
    } 
    else {
        Write-Host "Selenium module does not exist. Trying to install now."
        try {
            Install-Module -Name Selenium -RequiredVersion 3.0.1 -Scope CurrentUser
            Return "200"
        } 
        catch {
            throw "Couldn't install Selenium module."
            Return "100"
        }
    }
}