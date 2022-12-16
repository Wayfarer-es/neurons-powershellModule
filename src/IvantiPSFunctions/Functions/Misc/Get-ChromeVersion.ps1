 <#
    .SYNOPSIS
    Run to get Chrome version

    .DESCRIPTION
    Run to check if Chrome is installed and to return the version if it is.

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

#Function to generate authorization token using client credentials.
function Get-ChromeVersion {

    If ($IsWindows -or $Env:OS) {
        Try {
            return (Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' -ErrorAction Stop).'(Default)').VersionInfo.FileVersion;
        }
        Catch {
            Throw "Google Chrome not found in registry";
        }
    }
    ElseIf ($IsLinux) {
        Try {
            # this will check whether google-chrome command is available
            Get-Command google-chrome -ErrorAction Stop | Out-Null;
            return google-chrome --product-version;
        }
        Catch {
            Throw "'google-chrome' command not found";
        }
    }
    ElseIf ($IsMacOS) {
        $ChromePath = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
        If (Test-Path $ChromePath) {
            $Version = & $ChromePath --version;
            $Version = $Version.Replace("Google Chrome ", "");
            return $Version;
        }
        Else {
            Throw "Google Chrome not found on your MacOS machine";
        }
    }
    Else {
        Throw "Your operating system is not supported by this script.";
    }

}