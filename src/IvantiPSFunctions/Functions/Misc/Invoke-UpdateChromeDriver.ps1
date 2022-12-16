 <#
    .SYNOPSIS
    Update Chrome Driver for Selenium
    
    .DESCRIPTION
    Checks the latest version of Chrome and downloads the correct driver for it.

    .PARAMETER ChromeDriverOutputPath
    Mandatory. Tenant ID for the desired customer.

    .PARAMETER ChromeVersion
    Optional. Landscape for the desired customer.

    .PARAMETER ForceDownload
    Optional. Provide the data endpoint for which you want to delete data. 

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

function Invoke-UpdateChromeDriver {
    
    # store original preference to revert back later
    $_originalProgressPreference = $ProgressPreference;
    # setting progress preference to silently continue will massively increase the performance of downloading the ChromeDriver
    $ProgressPreference = 'SilentlyContinue'

    # Instructions from https://chromedriver.chromium.org/downloads/version-selection
    #   First, find out which version of Chrome you are using. Let's say you have Chrome 72.0.3626.81.
    $_chromeVersion = Get-ChromeVersion -ErrorAction Stop
    Write-Host "Google Chrome version $_chromeVersion found on machine"

    #   Take the Chrome version number, remove the last part, 
    $_chromeVersion = $_chromeVersion.Substring(0, $_chromeVersion.LastIndexOf("."));
    #   and append the result to URL "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_". 
    #   For example, with Chrome version 72.0.3626.81, you'd get a URL "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_72.0.3626".
    $_chromeDriverVersion = (Invoke-WebRequest "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$_chromeVersion").Content
    Write-Host "Latest matching version of Chrome Driver is $_chromeDriverVersion"
    
    # Get Chrome driver path by locating Selenium module path    
    $_seleniumModulePath = (Get-Module -LIstAvailable Selenium).path
    $_seleniumModulePathCheck = $_seleniumModulePath -match '^(.*[\\\/])'
    if ( $_seleniumModulePathCheck ) {
        $_seleniumModulePath = $matches[1]
    }

    # Set Chrome driver path
    If ($IsWindows -or $Env:OS) {
        $_chromeDriverPath = $_seleniumModulePath + "assemblies\"
    } ElseIf ($IsLinux) {
        $_chromeDriverPath = $_seleniumModulePath + "assemblies/linux/"
    } ElseIf ($IsMacOS) {
        $_chromeDriverPath = $_seleniumModulePath + "assemblies/macos/"
    } Else {
        Throw "Your operating system is not supported by this script."
        Exit
    }

    # Check Chrome driver version
    $_existingChromeDriverVersion = (& ($_chromeDriverPath + "chromedriver") --version) -split " "
    If ($_chromeDriverVersion -eq $_existingChromeDriverVersion[1]) {
        Write-Host "Chromedriver on machine is already latest version.";
        return @{"Status"="200"}
    }


    $_TempFilePath = [System.IO.Path]::GetTempFileName();
    $_TempZipFilePath = $_TempFilePath.Replace(".tmp", ".zip");
    Rename-Item -Path $_TempFilePath -NewName $_TempZipFilePath;
    $_TempFileUnzipPath = $_TempFilePath.Replace(".tmp", "");
    #   Use the URL created in the last step to retrieve a small file containing the version of ChromeDriver to use. For example, the above URL will get your a file containing "72.0.3626.69". (The actual number may change in the future, of course.)
    #   Use the version number retrieved from the previous step to construct the URL to download ChromeDriver. With version 72.0.3626.69, the URL would be "https://chromedriver.storage.googleapis.com/index.html?path=72.0.3626.69/".

    If ($IsWindows -or $Env:OS) {
        Invoke-WebRequest "https://chromedriver.storage.googleapis.com/$_chromeDriverVersion/chromedriver_win32.zip" -OutFile $_TempZipFilePath
        Expand-Archive $_TempZipFilePath -DestinationPath $_TempFileUnzipPath
        Move-Item "$_TempFileUnzipPath/chromedriver.exe" -Destination $_chromeDriverPath -Force
    }
    ElseIf ($IsLinux) {
        Invoke-WebRequest "https://chromedriver.storage.googleapis.com/$_chromeDriverVersion/chromedriver_linux64.zip" -OutFile $_TempZipFilePath
        Expand-Archive $_TempZipFilePath -DestinationPath $_TempFileUnzipPath
        Move-Item "$_TempFileUnzipPath/chromedriver" -Destination $_chromeDriverPath -Force
    }
    ElseIf ($IsMacOS) {
        Invoke-WebRequest "https://chromedriver.storage.googleapis.com/$_chromeDriverVersion/chromedriver_mac64.zip" -OutFile $_TempZipFilePath
        Expand-Archive $_TempZipFilePath -DestinationPath $_TempFileUnzipPath
        Move-Item "$_TempFileUnzipPath/chromedriver" -Destination $_chromeDriverPath -Force
    }
    
    #   After the initial download, it is recommended that you occasionally go through the above process again to see if there are any bug fix releases.
    
    # Clean up temp files
    Remove-Item $_TempZipFilePath
    Remove-Item $_TempFileUnzipPath -Recurse
    
    # reset back to original Progress Preference
    $ProgressPreference = $_originalProgressPreference

    Write-Host "Updated Chrome Driver located at $_chromeDriverPath"
    return @{"Status"="200"}
}