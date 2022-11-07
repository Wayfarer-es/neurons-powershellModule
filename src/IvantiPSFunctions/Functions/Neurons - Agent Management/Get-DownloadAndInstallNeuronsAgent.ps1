 <#
    .SYNOPSIS
    Downloads and installs the Ivanti Neurons agent.

    .DESCRIPTION
    Downloads and installs the Ivanti Neurons agent with the specified tenant ID and enrollment key.

    .PARAMETER TenantId
    Mandatory. Tenant ID for the desired customer.

    .PARAMETER EnrollmentKay
    Mandatory. The enrollment key for the desired Ivanti Neurons agent policy.
    
    .PARAMETER Path
    Optional. Provide a specific path from which to download and install the Ivanti Neurons agent.

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

function Get-DownloadAndInstallNeuronsAgent{

    param (
    
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$TenantId,
        
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$EnrollmentKay,

        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$Path="C:\Temp\IvantiCloudAgent.exe"

    )

    $_URL = "https://download.ivanticloud.com/d/Neurons/1/IvantiCloudAgent.exe"
    $_registrationString = "$TenantId_$EnrollmentKay"

    try {

        #Download the Neuorns agent
        Invoke-WebRequest $_URL -OutFile $_fileName

        #Install the Neurons agent
        Start-Process -FilePath "C:\Program Files\Ivanti\Ivanti Cloud Agent\STAgentCtl.exe" -ArgumentList "/register", "/cookie $_registrationString", "/baseurl https://agentreg.ivanticloud.com"
        Start-Sleep -Seconds 30
        Start-Process -FilePath "C:\Program Files\Ivanti\Ivanti Cloud Agent\STAgentCtl.exe.exe" -ArgumentList "/update"
        return 'Successfully downloaded and installed the Ivanti Neurons agent'

    } catch {

        Write-Error $_.Exception.InnerException.Message
        throw 'Unable to download and install the Ivanti Neurons agent'

    }

}