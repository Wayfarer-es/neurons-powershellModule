 <#
    .SYNOPSIS
    Returns a user freindly name for the different configuration types.

    .DESCRIPTION
    Returns the provider name or configuration type name for every connector.

    .PARAMETER ConfigurationTypeRecID
    Mandatory. The Rec ID for the configuration type.

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

function Get-NeuronsConnectorProviderByConfigTypeRecID {
    #Input parameters. These need to be collected at time of execution.
    param (
    
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [String]$ConfigurationTypeRecID

    )
    
    switch ( $ConfigurationTypeRecID.ToLower() )
    {
        "e595ff1c-1c37-42e6-a82d-72fa5e2b902c" { $_response = "ADCollector" }
        "01e9b5c0-c575-4f60-9319-02c664d8c678" { $_response = "Adobe" }
        "22c8baa6-b05e-41f2-92b0-7d75a0b9b457" { $_response = "AvalancheCollector" }
        "606e97b0-1899-4a89-828a-6803a3f69f04" { $_response = "AWSCollector" }
        "b1b556ff-fb62-4bc4-8c58-2068c5eb6c54" { $_response = "AzureADCollector" }
        "4defa658-470b-469e-8788-a23c39d4efd2" { $_response = "AzureCompute" }
        "768a1a81-a832-404a-ae48-1ce811dd9765" { $_response = "CDWCollector" }
        "8e8482b3-cc53-48f6-8f0f-f76ddf9c2054" { $_response = "ChromeOSCollector" }
        "59955083-87cb-408b-becf-9f07b5b1e88f" { $_response = "CrowdStrikeCollector" }
        "2b534d91-5c54-4935-acbd-a6df6d2380e0" { $_response = "CSMCollector" }
        "279c7c42-357b-41ce-959f-9716ac60892c" { $_response = "CSVCollector" }
        "e97000ee-fe1d-4dec-b576-7e9138931563" { $_response = "CynerioCollector" }
        "c8a62bb4-3b5e-473f-a5e4-81b73ee97383" { $_response = "DCDCollector" }
        "7cb57d45-316c-4df8-92e5-51f88112e851" { $_response = "DellWarrantyCollector" }
        "6ee7b474-d150-491e-a599-49cd8ba7a194" { $_response = "DSMCollector" }
        "e96a6ff0-9fdf-4e4f-86a0-ba282797b8f5" { $_response = "LDMS" }
        "afd402cd-304f-4eed-ba0f-8698b1087968" { $_response = "IESCollector" }
        "f24c3338-0824-4761-aacd-08ce1f2874c2" { $_response = "InsightCollector" }
        "ccdedc1f-6781-44ba-a05c-f1cdf1fb2dbe" { $_response = "IntelAmtCollector" }
        "014d0cba-e929-4be2-a553-e5ce5a403f3f" { $_response = "IntuneCollector" }
        "d064f75c-aa39-423b-b2ef-659b660fc884" { $_response = "ISeCCollector" }
        "d09ecb92-aef1-48b2-a2cc-c39224961e42" { $_response = "ISMCollector" }
        "5eca8d8e-e9f0-4f3e-baff-046c8e238c2e" { $_response = "JamfCollector" }
        "1fe2c203-81c1-4b5d-b51b-39678105dbb6" { $_response = "LenovoWarrantyCollector" }
        "8fa7fd4a-6fd3-450c-a969-e8b649b5a47c" { $_response = "MobileIronCollector" }
        "54e6ca5b-4379-4063-b432-7b2a30cf2439" { $_response = "M365Collector" }
        "612384ce-e0b1-4047-9a44-7a146789c79a" { $_response = "OktaCollector" }
        "96fbc03a-05fb-4630-a545-08f9e3bcdfd1" { $_response = "OneLogin" }
        "34965f22-8f22-472b-9298-84c503ca0b9b" { $_response = "PatchForSCCMCollector" }
        "889b1e8b-71cc-4262-9453-244e606ae321" { $_response = "PulseCollector" }
        "8b6a73d3-4ad2-4103-9b7b-f5f1b1b181f8" { $_response = "QualysCollector" }
        "eb002fe5-ad49-4184-8d35-3322e6196018" { $_response = "Rapid7Collector" }
        "d82f239d-3bea-43b9-a0dd-71246ab92093" { $_response = "SalesforceCollector" }
        "4411a352-2931-4297-8db8-8a26ee1a3116" { $_response = "SCCMCollector" }
        "8986c4c0-43a5-4f3a-8fdd-c40f8d76749c" { $_response = "ServiceNowCollector" }
        "f6eeea02-308d-412d-a5fd-c934013f8f0d" { $_response = "TenableConnector" }
        "6be17f72-ea14-448d-afab-3ad09fd4d7f0" { $_response = "VMware-vCenterCollector" }
        "d8131e1a-2f15-4571-a46e-508f32d80237" { $_response = "WorkSpaceOneCollector" }
    }

     return $_response

}