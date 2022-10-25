function ConvertTo-Array {
    param (
        [string[]]$arrayObjects
    )
    if ($null -eq $arrayObjects -or $arrayObjects.Count -eq 0) {
        $object = $null
        return $object 
    }
    else {
        try {
            $objectTable = New-Object System.Data.DataTable
            [void]$objectTable.Columns.Add("id", "System.String")
    
            foreach ($arrayObject in $arrayObjects) {
                $newRow = $objectTable.NewRow()
                $newRow.id = $arrayObject
                $objectTable.Rows.Add($newRow)
            }
            $object = $objectTable | Select-Object * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors 
            return $object
        }
        catch {
            $logMessage = "Unable to build data Table for this group."
            Write-Debug -Message $logMessage
        }
    }
}