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

		Context "Mandatory Parameters" {

			$Parameters = @{Parameter = 'AccountID' }

			It "specifies parameter <Parameter> as mandatory" -TestCases $Parameters {

				param($Parameter)

				(Get-Command Enable-PASCPMAutoManagement).Parameters["$Parameter"].Attributes.Mandatory | Should Be $true

			}

		}

		Context "Input" {

			BeforeEach {

				Mock Set-PASAccount -MockWith { }

				$InputObj = [pscustomobject]@{
					"AccountID"   = "12_3"

				}

			}

			It "sends request" {

				$InputObj | Disable-PASCPMAutoManagement -Reason "Pester Test"
				Assert-MockCalled Set-PASAccount -Times 1 -Exactly -Scope It

			}

			It "throws error if version requirement not met" {

				$Script:ExternalVersion = "1.2"

				{ $InputObj | Disable-PASCPMAutoManagement } | Should throw

				$Script:ExternalVersion = "0.0"

			}

		}

	}

}