 <#
    .SYNOPSIS
    Use this function to try a block of code with the specified number of retries.

    .DESCRIPTION
    Tries to invoke the provided block of code with the specified number of retries.  Will throw an error if it can't run the code in the specified number of retries.

    .PARAMETER ScriptBlock
    Mandatory. Block of  text  that will be executed.

    .PARAMETER Retries
    Optional. Integer to specify how many times to retry.  3 is the default.

    .PARAMETER Delay
    Optional. Integer to specify how much time (ms) to delay in between reties.  100 milleseconds is the default.


    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

function Invoke-Command {
    [CmdletBinding()]
    Param(
        [Parameter(Position=0, Mandatory=$true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Position=1, Mandatory=$false)]
        [int]$Retries = 3,

        [Parameter(Position=2, Mandatory=$false)]
        [int]$Delay = 1000
    )

    Begin {
        $Count = 0
        $Success = $null
    }

    Process {
        do {
            $Count++
            $DbgMessage = "Executing script block, try "+$Count
            Write-Debug $DbgMessage
            try {
                $ScriptBlock.Invoke()
                $Success = $true
                return
            } catch {
                Write-Error $_.Exception.InnerException.Message -ErrorAction Continue
                $Sleep = $Delay * [math]::Pow($Count,2)
                Start-Sleep -Milliseconds $Sleep
            }
        } until ($Count -eq $Retries -or $Success)
            # Throw an error after $Maximum unsuccessful invocations. Doesn't need
            # a condition, since the function returns upon successful invocation.
            throw 'Execution failed.'
    }
}