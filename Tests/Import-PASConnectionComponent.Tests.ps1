#Get Current Directory
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

#Get Function Name
$FunctionName = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -Replace ".Tests.ps1"

#Assume ModuleName from Repository Root folder
$ModuleName = Split-Path (Split-Path $Here -Parent) -Leaf

#Resolve Path to Module Directory
$ModulePath = Resolve-Path "$Here\..\$ModuleName"

#Define Path to Module Manifest
$ManifestPath = Join-Path "$ModulePath" "$ModuleName.psd1"

if ( -not (Get-Module -Name $ModuleName -All)) {

	Import-Module -Name "$ManifestPath" -ArgumentList $true -Force -ErrorAction Stop

}

BeforeAll {

	$Script:RequestBody = $null
	$Script:BaseURI = "https://SomeURL/SomeApp"
	$Script:ExternalVersion = "0.0"
	$Script:WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession

}

AfterAll {

	$Script:RequestBody = $null

}

Describe $FunctionName {

	InModuleScope $ModuleName {

		Mock Invoke-PASRestMethod -MockWith {
			[PSCustomObject]@{"ConnectionComponentID" = "SomeConnectionComponent" }
		}

		#Create a 512b file to test with
		$file = [System.IO.File]::Create("$env:Temp\test.zip")
		$file.SetLength(0.5kb)
		$file.Close()

		Context "Mandatory Parameters" {

			$Parameters = @{Parameter = 'ImportFile' }

			It "specifies parameter <Parameter> as mandatory" -TestCases $Parameters {

				param($Parameter)

				(Get-Command Import-PASConnectionComponent).Parameters["$Parameter"].Attributes.Mandatory | Should Be $true

			}

		}

		$response = Import-PASConnectionComponent -ImportFile $($file.name)

		Context "Input" {

			It "throws if InputFile does not exist" {
				{ Import-PASConnectionComponent -ImportFile SomeFile.txt } | Should throw
			}

			It "throws if InputFile resolves to a folder" {
				{ Import-PASConnectionComponent -ImportFile $pwd } | Should throw
			}

			It "throws if InputFile does not have a zip extention" {
				{ Import-PASConnectionComponent -ImportFile README.MD } | Should throw
			}

			It "sends request" {

				Assert-MockCalled Invoke-PASRestMethod -Times 1 -Exactly -Scope Describe

			}

			It "sends request to expected endpoint" {

				Assert-MockCalled Invoke-PASRestMethod -ParameterFilter {

					$URI -eq "$($Script:BaseURI)/API/ConnectionComponents/Import"

				} -Times 1 -Exactly -Scope Describe

			}

			It "uses expected method" {

				Assert-MockCalled Invoke-PASRestMethod -ParameterFilter { $Method -match 'POST' } -Times 1 -Exactly -Scope Describe

			}

			It "sends request with expected body" {

				Assert-MockCalled Invoke-PASRestMethod -ParameterFilter {

					$Script:RequestBody = $Body | ConvertFrom-Json

					($Script:RequestBody.ImportFile) -ne $null

				} -Times 1 -Exactly -Scope Describe

			}

			It "has a request body with expected number of properties" {

				($Script:RequestBody | Get-Member -MemberType NoteProperty).length | Should Be 1

			}

			It "has body content of expected length" {

				($Script:RequestBody.ImportFile).length | Should Be 512

			}

			It "throws error if version requirement not met" {
$Script:ExternalVersion = "1.0"
				{ Import-PASConnectionComponent -ImportFile $($file.name)  } | Should Throw
$Script:ExternalVersion = "0.0"
			}

		}

		Context "Output" {

			it "provides output" {

				$response | Should not BeNullOrEmpty

			}

			It "has output with expected number of properties" {

				($response | Get-Member -MemberType NoteProperty).length | Should Be 1

			}

			it "outputs object with expected typename" {

				$response | get-member | select-object -expandproperty typename -Unique | Should Be System.Management.Automation.PSCustomObject

			}



		}

	}

}