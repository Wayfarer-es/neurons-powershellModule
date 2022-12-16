function Get-Selenium {
    # *************************** Module Prep ***************************
    if ((Get-InstalledModule -Name 'Selenium' -RequiredVersion '3.0.1')) {
        Write-Host "Selenium module exists"
        return @{"Status"="200"}
    } 
    else {
        Write-Host "Selenium module does not exist. Trying to install now."
        try {
            $a = Start-Job -ScriptBlock {Install-Module -Name Selenium -RequiredVersion 3.0.1 -Scope CurrentUser}
            $a | Wait-Job
            if ($a.State -eq 'Completed') {
                Write-Host "Selenium module installed"
                return @{"Status"="200"}
            } else {
                throw "Couldn't install Selenium module."
            }
        } 
        catch {
            throw "Couldn't install Selenium module."
        }
    }
}