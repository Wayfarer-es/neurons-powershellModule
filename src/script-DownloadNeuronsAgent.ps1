$_tenantId = "5c5a81d6-ddf4-4671-9b8d-1129234436f9"
$_activationKey = "QGADwPYMqpdxdfncqJkbQdiWpw8TJtv5iGOgsF91BqqPELeDpx2TpJ18qjw6nV4tVcYupQjpsjFrsus363w9T6eEmbsywxM8znkhzAPzwoNdbI7erSvD3AbHY4zhmVM9"

function Invoke-NeuronsAgentRegistration {

    param (
    
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$TenantId,
        
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$EnrollmentKay

    )

    $_registrationString = "$TenantId`_$EnrollmentKay"

    Start-Process -FilePath "C:\Program Files\Ivanti\Ivanti Cloud Agent\STAgentCtl.exe" -ArgumentList "/register", "/cookie $_registrationString", "/baseurl https://agentreg.ivanticloud.com"

}