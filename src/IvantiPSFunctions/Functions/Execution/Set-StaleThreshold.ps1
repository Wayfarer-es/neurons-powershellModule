 <#
    .SYNOPSIS
    Run to check whether a record is withing the specified threshold or not.

    .DESCRIPTION
    Use this function to determine if a record's last seen date is within a customer provided stale threshold parameter.  Will return a true or false value.

    .PARAMETER StaleThreshold
    Mandatory. Integer that represents how many days of data to check against the provided last seen date.

    .PARAMETER LastSeen
    Mandatory. Date for the record when it was last seen.

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

#Set threshold to filter out devices based on desired time frame (e.g. only get devices active in the last 30 days). 
function Set-StaleThresholdInt {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [int]$StaleThreshold,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        $LastSeen
    )
   
    #Can use practically any date-time variable returned from the API for threshold value. Need an input parameter in this function (in this example $LastSeen) that you will input your threshold variable into at the time of execution.
    if ($StaleThreshold -ne 0 ) {
        if ($null -ne $LastSeen) {

            $timeSpan = New-TimeSpan -Start $LastSeen -End (Get-Date).ToUniversalTime()

            if ($StaleThreshold -ge $timeSpan.Days) {
                #Returns true since the record is within the stale threshold.
                return $true
            }
            else {
                #Returns false since the record is not within the stale threshold.
                return $false
            }
        }
        else {
            #If a date is not provided, then we will return false.  We won't import the data because we can't tell if the record is within the stale threshold or not.
            return $false
        }
    }
    else  {
        #If StaleThreshold is 0, then we will return true.  0 is essentially not providing a stale threshold.
        return $true
    }
}