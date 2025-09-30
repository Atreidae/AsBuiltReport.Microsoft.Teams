<#
.SYNOPSIS
    Connects to a Microsoft 365 tenant and exports offline data as JSON files for later use.

.DESCRIPTION
    Runs "Invoke-AsBuiltReport.Microsoft.Teams" against a specified tenant and saves the resulting data as JSON files in a folder named after the tenant.
    This is useful for storing custom, potentially nested, PowerShell objects offline for later use or testing.

.PARAMETER SampleTenant
    The name of the sample M365 tenant. This will be used as the folder name under the output path.

.PARAMETER SamplePath
    The root directory where the tenant folder and JSON files are located. Defaults to '../../samples/' relative to the script root.

.PARAMETER AllowOverwrite
    Switch to allow overwriting existing files in the output directory.

.EXAMPLE
    ./Export-AbrCsOfflineData.ps1 -SampleTenant "Contoso"

    This will connect to the "Contoso" tenant, run the report, and save the data as JSON files in the 'Contoso' folder under the output path.

.OUTPUTS
    None. JSON files are saved to the specified output path.

.NOTES
    Version:        0.1.0
    Author:         James Arber
    Twitter:        UCMadScientist
    Github:         Atreidae
    Credits:        Iain Brighton (@iainbrighton) - PScribo module
                    Tim Carman (@tpcarman) - AsBuiltReport core project

.LINK
    https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Teams
#>

## Todo: Add big frikken warning that exports contain sensitive data and should be handled appropriately!

function Test-AbrCsOfflineData {
    [CmdletBinding()]
    param (
        [Parameter()][String[]] $Target,
        [Parameter()][PSCredential] $Credential,
        [Parameter()][Switch] $MFA,
        [Parameter(Mandatory)][string]$TenantCachePath,
        [Parameter()][switch]$AllowOverwrite

    )

    begin {
        # Check output directory exists, if it does, warn the user and exit if not allowing overwrite
        $parentFolder = Split-Path -Path $TenantCachePath -Parent

        # Check if the parent folder exists
        if (-not (Test-Path $parentFolder)) {
            Throw "The specified cache data path '$parentFolder' doesnt exist. Unable to continue, Exiting."
        }

        # Test if the tenant folder exists, create if not, exit if exists and not allowing overwrite
        if (-not (Test-Path $TenantCachePath)) {
            New-Item -Path $TenantCachePath -ItemType Directory -Force | Out-Null
        }
        elseif (-not $AllowOverwrite) {
            Throw "The specified sample data path '$TenantCachePath' already exists. Use -AllowOverwrite to overwrite existing files. Exiting."
        }
        elseif ($AllowOverwrite) {
            Write-PScriboMessage -Plugin 'Module' -Message "The specified sample data path '$TenantCachePath' already exists. Existing files will be overwritten."
            Remove-Item -Path (Join-Path -Path $TenantCachePath -ChildPath '*.json') -Force -ErrorAction SilentlyContinue
        }
    }

    process {
        foreach ($key in $Data.Keys) {
            $value = $Data[$key]
            $json = $value | ConvertTo-Json -Depth 10
            $filePath = Join-Path -Path $tenantPath -ChildPath "$key.json"
            $json | Set-Content -Path $filePath -Encoding UTF8
        }
    }

    end {
        Write-Verbose "Offline data saved for tenant '$TenantName' in '$tenantPath'"
    }
}
