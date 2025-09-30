<#
.SYNOPSIS
    Saves offline data for a specified Microsoft 365 cmdlet as a JSON file.

.DESCRIPTION
    The Save-AbrCsOfflineData function takes a hashtable of variable names and their corresponding data (as PSObjects or arrays of PSObjects),
    and serializes each entry to a separate JSON file within a directory named after the tenant.
    This is useful for storing custom, potentially nested, PowerShell objects offline for later use or testing.

    Initially created to save sample data for testing purposes. Can also be used to save your own data for later use should for any reason you not want/cannot to connect to the tenant directly.

.PARAMETER TenantName
    The name of the Microsoft 365 tenant. This will be used as the folder name under the output path.

.PARAMETER Data
    A hashtable where each key is a variable name and each value is a PSObject or array of PSObjects to be saved as JSON.

.PARAMETER OutputPath
    The root directory where the tenant folder and JSON files will be created. Defaults to '../../samples/testtenant' relative to the script root.

.EXAMPLE
    $data = @{
        Users = $usersObject
        Teams = $teamsObject
    }
    Save-AbrCsOfflineData -TenantName "Contoso" -Data $data

    This will create JSON files for 'Users' and 'Teams' in the 'Contoso' folder under the output path.

.NOTES
        Version:        0.1.0
        Author:         James "UcMadScientist" Arber
        Twitter:        @UCMadScientist
        Github:         Atreidae
#>
function Save-AbrCsOfflineVariable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$Module:CachedTenant,
        [Parameter(Mandatory)][hashtable]$Data, # Key: variable name, Value: PSObject or array of PSObjects
        [Parameter()][switch]$AllowOverwrite

    )

    begin {
        # Ensure output directory exists
        $tenantPath = Join-Path -Path $OutputPath -ChildPath $TenantName
        if (-not (Test-Path $tenantPath)) {
            New-Item -Path $tenantPath -ItemType Directory -Force | Out-Null
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
