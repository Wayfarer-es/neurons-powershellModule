 <#
    .SYNOPSIS
    Use this function to build boundadapter or networkadapter array.

    .DESCRIPTION
    Creates datatable for boundadapter or network adapter based on how many pscustomObject in an arraylist of ip/mac addresses.

    .PARAMETER PhysicalAddresses
    Mandatory. Block of  text  that will be executed.

    .PARAMETER NetworkAdapter
    Optional. Determine whether boundadapter or networkadapter is built: Build Boundadapter set to default (NetworkAdapter = false)



    .NOTES
    Author:  Ivanti
    Version: 2.0.0
#>
function Edit-BoundAdapterArray {
    [CmdletBinding()]
    param(
        $PhysicalAddresses,
        [Parameter(Mandatory = $false)][bool]$NetworkAdapter = $false
    )
    $Number = 0
    $AdapterInfo = New-Object System.Data.DataTable
    [void]$AdapterInfo.Columns.Add("Number", "system.Int32")
    [void]$AdapterInfo.Columns.Add("PhysicalAddress", "system.string") 
    if($NetworkAdapter){
        $newRow = $AdapterInfo.NewRow()
        $newRow.Number = $Number
        $newRow.PhysicalAddress = [string]$PhysicalAddresses
        $AdapterInfo.Rows.Add($newRow)
    }
    else{
        [void]$AdapterInfo.Columns.Add("IPAddress", "system.string")
        foreach ($address in $PhysicalAddresses) {
            $newRow = $AdapterInfo.NewRow()
            $newRow.Number = $Number
            $newRow.IPAddress = $address.IPAddress
            $newRow.PhysicalAddress = $address.PhysicalAddress
            $AdapterInfo.Rows.Add($newRow)
            $Number++
        }
    }
    $AdapterArray = $AdapterInfo | Select-Object * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors 
    return [array]$AdapterArray
}