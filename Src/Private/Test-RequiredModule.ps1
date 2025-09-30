function Test-RequiredModule {
    <#
    .SYNOPSIS
    Function to check if the required version of the Microsoft Teams PowerShell module is installed
    .DESCRIPTION
    Function to check if the required version of the Microsoft Teams PowerShell module is installed
    This function is a little redundant as the PSD1 manifest file will also check for required modules, however this allows us to provide a more user friendly error message and instructions on how to install/update the module if required.
    Especially for users who are running from source rather than the published module.

    .PARAMETER Name
    The name of the required PowerShell module

    .PARAMETER Version
    The version of the required PowerShell module

    .EXAMPLE
    # Single module
    Test-RequiredModule -Name 'MicrosoftTeams' -Version '5.0.0'

    # Multiple modules via pipeline
    @(
        @{ Name = 'MicrosoftTeams'; Version = '5.0.0' }
        @{ Name = 'PnP.PowerShell'; Version = '2.0.0' }
    ) | Test-RequiredModule

    .NOTES
    Version:        0.2.0
    Author:         James "UcMadScientist" Arber
    Twitter:        @UCMadScientist
    Github:         Atreidae

    .LINK

    .VERSION HISTORY
    0.2.0:  Added pipeline support for multiple modules
            Renamed function from Get-RequiredModule to Test-RequiredModule to better reflect its purpose.
            Refactored version checking to use [version] type casting for more reliable comparisons.

    0.1.0: Initial build for AsBuiltReport.Microsoft.Teams
    #>
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        $Name,

        [Parameter(Mandatory = $true, ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        $Version
    )

    process {
        # Recast hashtable values to correct types

        [string]$ObjName = $Name.name
        [version]$ObjVersion = $Version.version
        Write-Verbose "Checking for required module '$ObjName' with minimum version '$ObjVersion'."
        # Check if the required module is installed and meets the minimum version requirement
        $RequiredModule = Get-Module -ListAvailable -Name $ObjName | Sort-Object -Property Version -Descending | Select-Object -First 1

        if (-not $RequiredModule) {
            throw "Module '$ObjName' is not installed and is required to run the Microsoft Teams As Built Report. Run 'Install-Module -Name $ObjName -MinimumVersion $ObjVersion' to install the required module. `n."
        }
        $ModuleVersion = $RequiredModule.Version
        if ([version]$ModuleVersion -lt [version]$ObjVersion) {
            throw "Module '$ObjName' version $ModuleVersion is installed. Version $ObjVersion or higher is required to run the Microsoft Teams As Built Report. `nRun 'Update-Module -Name $ObjName -MinimumVersion $ObjVersion -Force' to update. `nDont forget to restart your PowerShell session after updating the module. `n."
        }
        Write-Verbose "Module '$ObjName' version $ModuleVersion is installed and meets the minimum version requirement of $ObjVersion."

    }
}
