#Function to send out the record to the Ivanti Neurons agent
function Out-NeuronsRecord {
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$DataType,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [Object]$Object,

        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$DataSyncID
    )

    Write-Debug $Object
}