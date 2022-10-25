 <#
    .SYNOPSIS
    Ignores certificate errors.

    .DESCRIPTION
    Run this function to ignore certificate errors in API calls.

    .NOTES
    Author:  Ivanti
    Version: 1.0.0
#>

#Function to ignore cert errors
function Set-IgnoreCertificateErrors {
	[CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [bool]$Enable=$false
    )

	if ($Enable -eq $true) {
		try {
			$Provider = New-Object Microsoft.CSharp.CSharpCodeProvider
			$Compiler= $Provider.CreateCompiler()
			$Params = New-Object System.CodeDom.Compiler.CompilerParameters
			$Params.GenerateExecutable = $False
			$Params.GenerateInMemory = $True
			$Params.IncludeDebugInformation = $False
			$Params.ReferencedAssemblies.Add("System.DLL") > $null
			$TASource=@'
				namespace Local.ToolkitExtensions.Net.CertificatePolicy
				{
					public class TrustAll : System.Net.ICertificatePolicy
					{
						public TrustAll() {}
						public bool CheckValidationResult(System.Net.ServicePoint sp,System.Security.Cryptography.X509Certificates.X509Certificate cert, System.Net.WebRequest req, int problem)
						{
							return true;
						}
					}
				}
'@ 
			$TAResults=$Provider.CompileAssemblyFromSource($Params,$TASource)
			$TAAssembly=$TAResults.CompiledAssembly
				## We create an instance of TrustAll and attach it to the ServicePointManager
			$TrustAll = $TAAssembly.CreateInstance("Local.ToolkitExtensions.Net.CertificatePolicy.TrustAll")
				[System.Net.ServicePointManager]::CertificatePolicy = $TrustAll
		}
		catch {
			Write-Debug "Security policy already applied"
		}
	} else {
		[System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
	}

}