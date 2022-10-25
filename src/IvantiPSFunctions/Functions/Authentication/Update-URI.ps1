#Function used to check the URI protocol and standardize it.
function Update-URI {
    param (
        $Instance
    )

    #Checks if it's already in the correct format (ie. https://www.abc.com/)
    if ($Instance -match "^(https:\/\/)[\w.-]+\/") {
        $Instance = $Instance
    } #Checks if it's missing the / at the end (ie. https://www.abc.com)
    elseif ($Instance -match "^(https:\/\/)[\w.-]+") {
        $Instance = $Instance+"/"
    } #Checks if it's http and should be https (ie. http://www.abc.com/)
    elseif ($Instance -match "^(http:\/\/)[\w.-]+\/") {
        $Instance = $Instance.Replace("http","https")
    } #Checks if it's http and missing the / at the end (ie. http://www.abc.com)
    else {
        $Instance = $Instance.Replace("http","https")
        $Instance = $Instance+"/"
    }
    return $Instance
}