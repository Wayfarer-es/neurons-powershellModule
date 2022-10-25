# $_URL = "https://drive.google.com/uc?export=download&id=1EkBmzKcLgQXlenOhvM4Qmq_FY6RAJSrZ"8?
$_URL = "https://download.ivanticloud.com/d/Neurons/1/IvantiCloudAgent.exe"
$_fileName = "C:\Temp\IvantiCloudAgent.exe"
$_tenantId = "5c5a81d6-ddf4-4671-9b8d-1129234436f9"
$_activationKey = "QGADwPYMqpdxdfncqJkbQdiWpw8TJtv5iGOgsF91BqqPELeDpx2TpJ18qjw6nV4tVcYupQjpsjFrsus363w9T6eEmbsywxM8znkhzAPzwoNdbI7erSvD3AbHY4zhmVM9"

Invoke-WebRequest $_URL -OutFile $_fileName

Start-Process -FilePath $_fileName -WindowStyle Hidden -Verb RunAs -ArgumentList "/tenantid $_tenantId","/activationkey $_activationKey","/cloudhost https://agentreg.ivanticloud.com", "/mode unattended"

Start-Sleep -Seconds 30

Start-Process -FilePath "C:\Program Files\Ivanti\Ivanti Cloud Agent\STAgentManagement.exe" -ArgumentList "/update"