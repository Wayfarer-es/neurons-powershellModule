 <#
    .SYNOPSIS
    Registers a device to Ivanti Neurons.

    .DESCRIPTION
    Registers a device to Ivanti Neurons with the specified tenant ID and enrollment key.

    .PARAMETER TenantId
    Mandatory. Tenant ID for the desired customer.

    .PARAMETER EnrollmentKay
    Mandatory. The enrollment key for the desired Ivanti Neurons agent policy.
    
    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

function Invoke-NeuronsAgentRegistration {

    param (
    
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$TenantId,
        
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$EnrollmentKay

    )

    $_registrationString = "$TenantId_$EnrollmentKay"

    try {

        Start-Process -FilePath "C:\Program Files\Ivanti\Ivanti Cloud Agent\STAgentCtl.exe" -ArgumentList "/register", "/cookie $_registrationString", "/baseurl https://agentreg.ivanticloud.com"
        return 'Successfully registered the Ivanti Neurons agent'

    } catch {

        Write-Error $_.Exception.InnerException.Message
        throw 'Unable to register the Ivanti Neurons agent'

    }

}