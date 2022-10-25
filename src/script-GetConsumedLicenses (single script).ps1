#Set parameters to run
$_clientID = "[insert client id here]"
$_clientSecret = "[insert client secret here]"
$_authURL = "[insert auth URL here]"
$_scope = "dataservices.read"
$_landscape = "NVU"
$_csvName = "Neurons Consumed Licenses"
$_daysAgo = (Get-Date).AddDays(-90)
$_date = Get-Date -Date $_daysAgo -Format 'yyyy-MM-dd'

#Static script parameters
$_filter = "DiscoveryMetadata.Providers.processDate gt '$_date' and (contains(OS.Name, 'windows') or contains(OS.Name, 'mac') or (contains(OS.Name, 'red hat') and contains(OS.Name, '7')) or (contains(OS.Name, 'centos') and contains(OS.Name, '7')) or not contains(OS.Name, 'phone'))"
$_select = "DeviceName,OS/Name,DiscoveryMetadata/Providers/processDate"

# ======================================= Functions ======================================= 
function Get-NeuronsData {
    #Input parameters. These need to be collected at time of execution.
    param (
    
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$Landscape,
        
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$DataEndpoint="device",

        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$FilterString="exists(DiscoveryId)",

        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$SelectString="DiscoveryId",

        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [bool]$ExportToCsv=$false,

        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$CSVName="Neurons Report",

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$Token

    )
    
    switch ( $Landscape.ToLower() )
    {
        "uks" { $_landscape = "uksprd-sfc.ivanticloud.com" }
        "uku" { $_landscape = "ukuprd-sfc.ivanticloud.com" }
        "nvz" { $_landscape = "nvzprd-sfc.ivanticloud.com" }
        "nvu" { $_landscape = "nvuprd-sfc.ivanticloud.com" }
        "mlz" { $_landscape = "mlzprd-sfc.ivanticloud.com" }
        "mlu" { $_landscape = "mluprd-sfc.ivanticloud.com" }
    }

    switch ( $DataEndpoint.ToLower() )
    {
        "device" { $_dataEndpoint = "device" }
        "user" { $_dataEndpoint = "data" }
        "group" { $_dataEndpoint = "data" }
        "invoice" { $_dataEndpoint = "data" }
        "business units" { $_dataEndpoint = "data" }
        "entitlement" { $_dataEndpoint = "data" }
        "data" { $_dataEndpoint = "data" }
    }

    #Split select values into array for use throughout the function
    $_selectValues = $SelectString.Split(",") 

    #CSV setup
    if ( $ExportToCsv -eq $true ) {
        $_reportRunTime = Get-Date -Format "yyyy-MM-dd HH-mm-ss"
        $_csvPath = "C:\Ivanti\Reports\" + $CSVName + " - " + $_reportRunTime + ".csv"

        foreach ( $_selectValue in $_selectValues ) {
            $_selectValue=$_selectValue.Replace("/", ".")
            $_csvHeader += '"'+$_selectValue+'",'
        }

        $_csvHeader.Substring( 0, $_csvHeader.length -1 ) | Add-Content -Path $_csvPath
    }

    #Filter cleanup
    IF ( [string]::IsNullOrWhitespace($FilterString) ) { $FilterString = "exists(DiscoveryId)" }

    #Query URL setup
    $_queryURL = "https://$_landscape/api/discovery/v1/$_dataEndpoint"+"?`$filter=$FilterString&`$select=$SelectString"

    #Headers setup
    $_headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $_headers.Add("content-type", "application/json;charset=UTF-8")
    $_headers.Add("Authorization", "Bearer $Token")

    #Results variable setup
    $_page = 1
    $_results = @()

    do {
        #Initial query to Neurons to get result count
        $_response = Invoke-Command -ScriptBlock {
            Invoke-RestMethod -Uri $_queryURL -Method 'GET' -Headers $_headers
        }

        #Convert to valide json if needed
        if ( $_response.gettype() -eq [string] ) {
            $_response = $_response | ConvertFrom-InvalidJson
        }

        # calculate PageSize for Number of Pages calculation
        If($_page -eq 1){
            if( $_response.value.Count -ne $_response.'@odata.count') {
                $PageSize = $_response.value.Count
            } else {
                $PageSize = $_response.'@odata.count'
            }
        }
 
        #Get the number of pages
        if (!$_pages) {
            $_pages = [math]::ceiling( $_response.'@odata.count' / $PageSize )
        }

        $_dbgMessage = "Processing page $_page of $_pages"
        Write-Host $_dbgMessage

        #Process and submit each record in the batch
        foreach ( $_result in $_response.value ) {
            $_resultRow = ""

            foreach ( $_selectValue in $_selectValues ) {
                $_selectValueArray = $_selectValue.split("/")
                $_resultItem = $_result

                foreach ( $_selectValueArrayItem in $_selectValueArray ) {
                    $_resultItem = $_resultItem.$_selectValueArrayItem
                }

                $_resultRow += '"'+$_resultItem+'",'
            }

            $_resultRow = $_resultRow.Substring( 0, $_resultRow.length -1 )

            if ( $ExportToCsv -eq $true) {
                $_resultRow | Add-Content -Path $_CSVPath
            }
            $_results += $_resultRow
        }

        $_queryURL = $_response.'@odata.nextLink'
        $_page++
       
    } until ( $_page -ge ( $_pages + 1) )

    if ( $ExportToCsv -eq $true ) {
        $_dbgMessage = "Successfully got "+$_results.count+' records. CSV file is located at "'+$_csvPath+'"'
        return $_dbgMessage
    }
    return $_results
}
function Get-AccessToken {
    param (

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$AuthURL,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$ClientID,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$ClientSecret,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$Scopes

    )

    #Build the request body and header. This will be done differently depending on the API's authorization method.
    $_body = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $_body.Add("grant_type", "client_credentials")
    $_body.Add("client_id", $ClientID)
    $_body.Add("client_secret", $ClientSecret)
    $_body.Add("scope", $Scopes)

    $_headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $_headers.Add("Accept", "application/json")
    $_headers.Add("Content-Type", "application/x-www-form-urlencoded")

    $_token = Invoke-RestMethod -Uri $AuthURL -Method POST -Headers $_headers -Body $_body 

    return $_token.access_token
}
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

# ======================================= Run Code ======================================= 
if ( $_userJWT) { $_token = $_userJWT } else { $_token = Get-AccessToken -AuthURL $_authURL -ClientID $_clientID -ClientSecret $_clientSecret -Scopes $_scope }

$_results = Invoke-Command -ScriptBlock {
    Get-NeuronsData -Landscape $_landscape -FilterString $_filter -SelectString $_select -ExportToCsv $true -CSVName $_csvName -Token $_token 
}

$_results