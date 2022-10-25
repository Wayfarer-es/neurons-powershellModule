 <#
    .SYNOPSIS
    Use this function to send data to a specified Splunk HEC.

    .DESCRIPTION
    Sends a json document to an HTTP event collector for a given Splunk Enterprise instance.

    .PARAMETER SplunkServer
    Mandatory. Provide the desired Splunk Server or IP address.

    .PARAMETER Token
    Mandatory. Provide the Splunk HEC token.

    .PARAMETER Token
    Mandatory. Provide the json data to send.

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

function Send-SplunkData {
    [CmdletBinding()]
    Param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$SplunkServer,

        [Parameter(Position=1, Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Position=2, Mandatory=$true)]
        [string]$Data,

        [Parameter(Position=3, Mandatory=$false)]
        [string]$HostName = (hostname),

        [Parameter(Position=4, Mandatory=$false)]
        [System.DateTime]$DateTime = (Get-Date)
    )

begin {
$code= @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
Add-Type -TypeDefinition $code -Language CSharp
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}
    process {
        #URL setup
        $_splunkURL = "https://$SplunkServer`:8088/services/collector/event"

        #Headers setup
        $_headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $_headers.Add("content-type", "application/json;charset=UTF-8")
        $_headers.Add("Authorization", "Splunk $Token")

        # Splunk events can have a 'time' property in epoch time. If it's not set, use current system time.
        $_unixEpochStart = New-Object -TypeName DateTime -ArgumentList 1970,1,1,0,0,0,([DateTimeKind]::Utc)
        $_unixEpochTime = [int]($DateTime.ToUniversalTime() - $_unixEpochStart).TotalSeconds

        #Body setup
        $_body = ConvertTo-Json -InputObject @{event=$Data; host=$HostName; time=$_unixEpochTime} -Compress

        $_response = Invoke-RestMethod -Uri $_splunkURL -Method 'POST' -Headers $_headers -Body $_body
        if($_response.text -ne "Success") {$_response} 
    }
}